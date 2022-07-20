# AMFinder - amfinder_superresolution.py
#
# MIT License
# Copyright (c) 2021 Edouard Evangelisti, Carl Turner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

import os
import sys
import cv2
import numpy as np
import datetime
import matplotlib.pyplot as plt

from tensorflow.keras.optimizers import Adam
from keras.layers import Input, Dense, BatchNormalization, Add
from keras.layers import PReLU, LeakyReLU
from keras.layers.convolutional import UpSampling2D, Conv2D
from keras.models import Model
# From keras 2.5, the following will be replaced by:
from tf_agents.networks import network
# Thanks to matevzl533 for reporting this. 
# Reference: https://www.tensorflow.org/agents/tutorials/8_networks_tutorial
#from keras.engine.network import Network
from keras import backend as K

import amfinder_model as AmfModel
import amfinder_config as AmfConfig
import amfinder_segmentation as AmfSegm

BIN_SIZE = 3
CHANNELS = 3
HR_EDGE = 126
LR_EDGE = HR_EDGE // BIN_SIZE
LR_SHAPE = (LR_EDGE, LR_EDGE, CHANNELS)
HR_SHAPE = (HR_EDGE, HR_EDGE, CHANNELS)
OPTIMIZER = Adam(0.0002, 0.5)



def preprocess(tile_list):
    """
    For super resolution, images must be normalized to [-1; 1] for use with
    tanh activation function.
    """
    return (np.array(tile_list, np.float32) / 127.5) - 1.0



def restore(tile_list):

    return np.uint8((tile_list + 1) * 127.5)




# Reference: https://en.wikipedia.org/wiki/Peak_signal-to-noise_ratio
def PSNR(y_true, y_pred):
    """
    PSNR stands for Peek Signal to Noise Ratio.
    The equation is:
    PSNR = 20 * log10(MAX_I) - 10 * log10(MSE)

    Since input is scaled from -1 to 1, MAX_I = 1, and 
    thus 20 * log10(1) = 0. Only the last part of 
    the equation is therefore necessary.
    """
    return -10.0 * K.log(K.mean(K.square(y_pred - y_true))) / K.log(10.0) 



# Reference: https://stackoverflow.com/a/56135413 
def fast_downsample(tile):
    """
    Fast image downsampling method.
    """

    tmp = tile.reshape((15, BIN_SIZE, 15, BIN_SIZE, 3)).max(3).max(1)
    return cv2.resize(tmp, 42, cv2.INTER_NEAREST)


def get_tiles(paths):

    hr_tiles = []
    lr_tiles = []   

    # Note: using tiles smaller than 126x126 pixels as high-resolution
    # tiles for SRGAN training does not make sense.
    edge = max(AmfConfig.get('tile_edge'), 126)
    AmfConfig.set('tile_edge', edge)  

    for path in paths:
    
        image = AmfSegm.load(path)

        hr_tile_set = AmfSegm.mosaic(image, edge=edge)
        hr_tiles.extend(hr_tile_set)

        lr_tile_set = [fast_downsample(tile) for tile in hr_tile_set]
        lr_tiles.extend(lr_tile_set)

    # (N, HR_EDGE, HR_EDGE, CHANNELS)
    hr_tiles = preprocess(hr_tiles)
    # (N, LR_EDGE, LR_EDGE, CHANNELS)
    lr_tiles = preprocess(lr_tiles)

    return list(zip(hr_tiles, lr_tiles))



def build_feature_extractor():

    # CNN2 model gives good results.
    model = AmfModel.load(name='CNN2v1.h5')
    # Layer C22 has an output shape of (56, 56, 64).
    model.outputs = [model.get_layer('C22').output]
    img = Input(shape=HR_SHAPE)
    img_features = model(img)
    return Model(img, img_features)



def d_block(layer_input, filters, strides=1, batch_norm=True):
    """Discriminator layer"""
    d = Conv2D(filters,
               kernel_size=3,
               strides=strides,
               padding='same')(layer_input)
    d = LeakyReLU(alpha=0.2)(d)
    if batch_norm:
        d = BatchNormalization(momentum=0.8)(d)
    return d



def build_discriminator():
    
    df = 64

    d0 = Input(shape=HR_SHAPE)
    d1 = d_block(d0, df, batch_norm=False)
    d2 = d_block(d1, df, strides=2)
    d3 = d_block(d2, df * 2)
    d4 = d_block(d3, df * 2, strides=2)
    d5 = d_block(d4, df * 4)
    d6 = d_block(d5, df * 4, strides=2)
    d7 = d_block(d6, df * 8)
    d8 = d_block(d7, df * 8, strides=2)
    d9 = Dense(df * 16)(d8)
    d10 = LeakyReLU(alpha=0.2)(d9)
    validity = Dense(1, activation='sigmoid')(d10)
    return Model(d0, validity, name='discriminator')



def residual_block(layer_input):
    """Residual block described in paper"""
    d = Conv2D(64, kernel_size=3, strides=1, padding='same')(layer_input)
    d = BatchNormalization(momentum=0.8)(d)
    d = PReLU(shared_axes = [1,2])(d)
    d = Conv2D(64, kernel_size=3, strides=1, padding='same')(d)
    d = BatchNormalization(momentum=0.8)(d)
    d = Add()([d, layer_input])
    return d



def upscale_block(layer_input):
    """Layers used during upsampling"""
    u = Conv2D(256, kernel_size=3, strides=1, padding='same')(layer_input)
    u = UpSampling2D(size=3)(u)
    u = PReLU(shared_axes=[1,2])(u)
    return u



def build_generator(residual_blocks=5):

    # Low resolution image input
    img_lr = Input(shape=LR_SHAPE)

    # Pre-residual block
    c1 = Conv2D(64, kernel_size=9, strides=1, padding='same')(img_lr)
    c1 = PReLU(shared_axes=[1,2])(c1)

    # Propogate through residual blocks
    r = residual_block(c1)
    for _ in range(residual_blocks - 1):
        r = residual_block(r)

    # Post-residual block
    c2 = Conv2D(64, kernel_size=3, strides=1, padding='same')(r)
    c2 = PReLU(shared_axes=[1,2])(c2)
    #c2 = BatchNormalization(momentum=0.8)(c2)
    c2 = Add()([c2, c1])

    # Upsampling (original code had two blocks to achieve x4)
    # Instead we have a single block which achieves x3.
    u2 = upscale_block(c2)

    # Generate high resolution output. For tanh activation function, see:
    # https://towardsdatascience.com/gan-ways-to-improve-gan-performance-acf37f9f59b
    gen_hr = Conv2D(CHANNELS, 
                    kernel_size=9,
                    strides=1,
                    padding='same',
                    activation='tanh')(u2)

    return Model(img_lr, gen_hr, name='generator')



def get_random_tile_pairs(tiles, batch_size=1, training=True):
    """
    Return randomly selected tile pairs.
    """

    indices = np.random.choice(len(tiles), size=batch_size)
    
    may_flip = lambda x: x
    
    if training and np.random.random() < 0.5:
    
        may_flip = lambda x: np.fliplr(x)
    
    selection = [tiles[i] for i in indices]

    hr_tiles = np.array([may_flip(x[0]) for x in selection])
    lr_tiles = np.array([may_flip(x[1]) for x in selection])

    return hr_tiles, lr_tiles



def train(paths, batch_size=2, sample_interval=20):
    """
    Trains a SRGAN.
    """

    print('* (super-resolution) Building feature extractor')
   
    feature_extractor = build_feature_extractor()
    feature_extractor.trainable = False
    feature_extractor.compile(loss='mse',
                              optimizer=OPTIMIZER,
                              metrics=['accuracy'])

    print('* (super-resolution) Building discriminator')

    discriminator = build_discriminator()
    
    if AmfConfig.get('discriminator') is not None:
    
        discriminator.load_weights(AmfConfig.get('discriminator'))

    discriminator.compile(loss='mse',
                          optimizer=OPTIMIZER,
                          metrics=['accuracy'])

    print('* (super-resolution) Building generator')

    generator = build_generator()
    
    if AmfConfig.get('generator') is not None:
    
        generator.load_weights(AmfConfig.get('generator'))

    generator.compile(loss='mse',
                      optimizer=OPTIMIZER,
                      metrics=['mse', PSNR])

    # High res. and low res. images
    img_hr = Input(shape=HR_SHAPE)
    img_lr = Input(shape=LR_SHAPE)

    # Generate high res. version from low res.
    fake_hr = generator(img_lr)

    # Extract image features of the generated img
    fake_features = feature_extractor(fake_hr)

    # For the combined model we will only train the generator
    # Using Network removes warnings.
    # https://github.com/keras-team/keras/issues/8585#issuecomment-412728017
    frozen_discriminator = Network(discriminator.inputs,
                                   discriminator.outputs,
                                   name='frozen_discriminator')

    frozen_discriminator.trainable = False

    # Discriminator determines validity of generated high res. images
    validity = frozen_discriminator(fake_hr)

    gan_model = Model(inputs=[img_lr, img_hr],
                      outputs=[validity, fake_features],
                      name='SRGAN')

    # TODO: display in verbose mode?
    #generator.summary()
    #discriminator.summary()
    #gan_model.summary()
    #sys.exit(0)

    gan_model.compile(loss=['binary_crossentropy', 'mse'],
                      loss_weights=[1e-3, 1],
                      optimizer=OPTIMIZER)
                    
    tiles = get_tiles(paths)
    epochs = len(tiles) * 200

    # Annotations for original high-resolution images (valid), and
    # newly generated images (fake). Annotations are given so the
    # discriminator learns to identify fake images. Both tables
    # have shape (batch_size, 8, 8, 1) to tell which parts
    # of the generated images were identified as fake.
    valid = np.ones((batch_size,) + (8, 8, 1))
    fake = np.zeros((batch_size,) + (8, 8, 1))
    start_time = datetime.datetime.now()

    base_dir = os.path.join(AmfConfig.get_appdir(), 'trained_networks')

    for epoch in range(epochs):

        print('Epoch {}/{}... '.format(epoch + 1, epochs), end='')

        hr_tile, lr_tile = get_random_tile_pairs(tiles,
                                                 batch_size=batch_size)
        
        # From low res. image generate high res. version
        # (N, LR_EDGE * 4, LR_EDGE * 4, CHANNELS)
        fake_hr = generator.predict(lr_tile)

        # Train the discriminators
        # (original images = real / generated = Fake)
        d_loss_real = discriminator.train_on_batch(hr_tile, valid)
        d_loss_fake = discriminator.train_on_batch(fake_hr, fake)
        d_loss = 0.5 * np.add(d_loss_real, d_loss_fake)

        hr_tile, lr_tile = get_random_tile_pairs(tiles,
                                                 batch_size=batch_size)

        # The generators want the discriminators 
        # to label the generated images as real
        #valid = np.ones((batch_size, 1))

        # Extract ground truth image features using pre-trained CNN1 model
        image_features = feature_extractor.predict(hr_tile)
        
        # Train the generators
        g_loss, _, _ = gan_model.train_on_batch([lr_tile, hr_tile],
                                                [valid, image_features])

        elapsed_time = datetime.datetime.now() - start_time
        # Plot the progress
        print('time:', elapsed_time, 'g_loss:', g_loss, 'd_loss:', d_loss)

        # Save image samples to see progress.
        if (epoch + 1) % sample_interval == 0:
            save_sample_images(epoch, generator, tiles)
            discriminator.save_weights(os.path.join(base_dir, 'disc/srgan_disc{}.h5'.format(epoch+1)))
            generator.save_weights(os.path.join(base_dir, 'gen/srgan_gen{}.h5'.format(epoch+1)))

    # TODO: improve this.
    discriminator.save_weights(os.path.join(base_dir, 'disc/srgan_disc_final.h5'))
    generator.save_weights(os.path.join(base_dir, 'gen/srgan_gen_final.h5'))




def initialize(nrows, ncols):
    """
    Creates an empty image.
    """
    
    canvas = None
    
    if AmfConfig.get('super_resolution'):
    
        canvas = np.zeros([nrows * 126, ncols * 126, 3], dtype=np.uint8)
        canvas.fill(255)

    return canvas



def generate(sr_image, row, r):

    # Super-resolution is not active, then return the row unaltered.
    if sr_image is None:

        return row

    else:
    
        sr_row = improve(row)

        x_ini = 0
        y_ini = r * 126
        # Update the image.
        
        for i, tile in enumerate(sr_row): 
        
            sr_image[y_ini:y_ini + 126, i * 126:(i + 1) * 126] = tile

        return sr_row


GENERATOR = None
def improve(raw_tiles):
    """
    Generate high-resolution versions of the given tiles.
    """
    
    global GENERATOR
    
    if GENERATOR is None:
   
        GENERATOR = build_generator()

        GENERATOR.load_weights(AmfConfig.get('generator'))

        GENERATOR.compile(loss='mse',
                          optimizer=OPTIMIZER,
                          metrics=['mse', PSNR])
    
    return restore(GENERATOR.predict(preprocess(raw_tiles)))



def save_sample_images(epoch, generator, tiles, batch_size=2):
    r, c = batch_size, 4

    imgs_hr, imgs_lr = get_random_tile_pairs(tiles,
                                             batch_size=batch_size,
                                             training=False)

    fake_hr = generator.predict(imgs_lr)

    # Restore pixel values.
    imgs_lr = restore(imgs_lr)
    imgs_in = [cv2.resize(x,
                          dsize=(HR_EDGE, HR_EDGE),
                          interpolation=cv2.INTER_CUBIC) for x in imgs_lr]
    fake_hr = restore(fake_hr)
    imgs_hr = restore(imgs_hr)

    # Save generated images together with originals.
    titles = ['Low resolution', 'Interpolation',
              'Generated', 'High resolution']
    fig, axs = plt.subplots(r, c)
    fig.suptitle('AMFinder SRGAN epoch {}'.format(epoch + 1), fontsize=20)

    for row in range(r):
        for col, image in enumerate([imgs_lr, imgs_in, fake_hr, imgs_hr]):
            axs[row, col].imshow(image[row])
            axs[row, col].set_title(titles[col])
            axs[row, col].axis('off')

    fig.savefig('tmp/sr-output/SR_output_{}.png'.format(epoch + 1))
    plt.close()

    

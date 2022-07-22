# AMFinder - amfinder_model.py
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



"""
ConvNet Builder.

Builds the convolutional neural networks used by AMFinder.

Constants
-----------
INPUT_SIZE - Size (in pixels) of input images.
CNN1_NAME - Name of the root segmentation network.
CNN2_NAME - Name of the AM fungal structure prediction network.

Functions
------------
:function convolutions: Builds convolution/maxpooling blocks.
:function fc_layers: Builds fully connected/dropout layers.
:function create_cnn1: Builds a network for root segmentation.
:function create_cnn2: Builds a network for AM fungal structure prediction.
:function load: main function, to be called from outside.
"""



import os
import keras

from keras.models import Model
from keras.layers import Input, Conv2D, MaxPooling2D, Flatten, Dense, Dropout
# From keras 2.5, the following will be replaced by:
# from keras.optimizers import adam_v2
# Thanks to matevzl533 for reporting this. 
# Reference: https://stackoverflow.com/a/68704757
from keras.optimizers import Adam
from keras.initializers import he_uniform

import amfinder_log as AmfLog
import amfinder_config as AmfConfig



INPUT_SIZE = 126
CNN1_NAME = 'col'
CNN2_NAME = 'myc'


def convolutions():
    """
    Builds convolution/maxpooling blocks.
    """

    kc = 32
    input_layer = Input(shape=(INPUT_SIZE, INPUT_SIZE, 3))

    # Convolution block 1: 126x126 -> 120x120
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C11')(input_layer)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C12')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C13')(x)

    x = MaxPooling2D(pool_size=2, name='M1')(x)

    kc *= 2 # 64

    # Convolution block 2: 60x60 -> 56x56
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C21')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C22')(x)

    x = MaxPooling2D(pool_size=2, name='M2')(x)

    kc *= 2 # 128

    # Convolution block 3: 28x28 -> 24x24
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C31')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C32')(x)

    x = MaxPooling2D(pool_size=2, name='M3')(x)

    kc *= 2 # 256

    # Last convolution: 12x12 -> 10x10
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C4')(x)

    # Final size: 5x5
    x = MaxPooling2D(pool_size=2, name='M4')(x)
    flatten = Flatten(name='F')(x)

    return (input_layer, flatten)



def fc_layers(x, label, count=1, activation='sigmoid'):
    """
    Builds fully connected layers (with dropout).
    
    :param x: last layer of conv/maxpool blocks (= Flatten). 
    :param label: Either 'RS' (root segmentation) or 'A', 'V', 'I', 'H'.
    :param count: Size of the output dense layer (defaults to 1).
    :param activation: Activation function (defaults to sigmoid).
    :return: CNN output (Dense) to use with Keras Model.
    :rtype: tensorflow.python.framework.ops.Tensor
    """

    x = Dense(128, kernel_initializer=he_uniform(), activation='relu',
              name = f'FC{label}1')(x)
    x = Dropout(0.3, name = f'D{label}1')(x)
    x = Dense(64, kernel_initializer=he_uniform(), activation='relu',
              name = f'FC{label}2')(x)
    x = Dropout(0.2, name = f'D{label}2')(x)
    output = Dense(count, activation=activation, name=label)(x)

    return output



def create_cnn1():
    """
    Builds a single-label, multi-class classifier to discriminate
    colonized (Y) and non-colonized (N) roots, and background (X).
    """

    input_layer, flatten = convolutions()
    output_layer = fc_layers(flatten, 'RS', count=3, activation='softmax')

    model = Model(inputs=input_layer,
                  outputs=output_layer,
                  name=CNN1_NAME)

    opt = Adam(learning_rate=AmfConfig.get('learning_rate'))
    model.compile(loss='categorical_crossentropy',
                  optimizer=opt,
                  metrics=['acc'])

    return model



def create_cnn2():
    """
    Builds a multi-label, single-class classifier to identify
    arbuscules (A), vesicles (V), hyphopodia (H), and
    intraradical hyphae (IH).
    """

    input_layer, flatten = convolutions()
    output_layers = [fc_layers(flatten, x) for x in AmfConfig.get('header')]

    model = Model(inputs=input_layer,
                  outputs=output_layers,
                  name=CNN2_NAME)

    opt = Adam(learning_rate=AmfConfig.get('learning_rate'))
    model.compile(loss='binary_crossentropy',
                  optimizer=opt,
                  metrics=['acc'])

    return model



def load(name=None):
    """
    Loads or initialises a convolutional neural network.
    """

    if name is not None:
    
        path = os.path.join(AmfConfig.get_appdir(), 'trained_networks', name)

    else:

        path = AmfConfig.get('model')

    if path is not None and os.path.isfile(path):
    
        AmfLog.text(f'Model: {path}')
        model = keras.models.load_model(path)

        if model.name == CNN1_NAME:

            AmfConfig.set('level', 1)

        else:

            AmfConfig.set('level', 2)
            
        AmfLog.text(f'Classes: {AmfConfig.get_class_documentation()}.')
        return model

    else:

        if AmfConfig.get('run_mode') == 'train':

            AmfLog.text('Initializes a new network.')

            if AmfConfig.get('level') == 1:

                return create_cnn1()

            else:

                return create_cnn2()
        
        else: # missing pre-trained model in prediction mode.
        
            AmfLog.error('A pre-trained model is required in prediction mode',
                         exit_code=AmfLog.ERR_NO_PRETRAINED_MODEL)



def filter(model, layer_type):
    """
    Return all layers from a <model> that belong to a given <layer_type>.
    """

    return [x for x in model.layers if isinstance(x, layer_type)]



def get_feature_extractors(model):
    """
    Builds submodels for all convolutional layers (Conv2D). 
    """
    
    return [(x, Model(model.input, x.output)) for x in filter(model, Conv2D)]


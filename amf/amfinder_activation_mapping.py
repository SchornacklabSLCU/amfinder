# AMFinder - amfinder_activation_mapping.py
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
    Implements the Grad-CAM algorithm

"""

import cv2
import cmapy
import keras
import matplotlib
import numpy as np
import tensorflow as tf
from keras import Input
from keras import Model
from keras.layers import Conv2D
from keras.layers import Dense
from tensorflow.keras import backend as K

import amfinder_log as AmfLog
import amfinder_config as AmfConfig



def initialize(nrows, ncols):
    """
    Create blank images to accommodate activation maps of each annotation class.

    PARAMETERS
        - nrows: number of tiles on Y axis (image height).
        - ncols: number of tiles on X axis (image width).

    Returns a list containing as many blank images as annotation classes
    at the current level (cf. `AmfConfig.get('header')`).
    """

    if AmfConfig.get('generate_cams'):

        # Create an empty image, to be used as template.
        edge = AmfConfig.get('tile_edge')
        blank = np.zeros((nrows * edge, ncols * edge, 3), np.uint8)
       
        # Create copies of the template blank image for each class.
        return [blank.copy() for _ in AmfConfig.get('header')]



def compute_cam(model, classifier_layer_names, tile):
    # First, we create a model that maps the input image to the activations
    # of the last conv layer
    last_conv_layer = model.get_layer('C4')
    last_conv_input = Input
    last_conv_layer_model = Model(model.inputs, last_conv_layer.output)

    # Second, we create a model that maps the activations of the last conv
    # layer to the final class predictions
    classifier_input = Input(shape=last_conv_layer.output.shape[1:])
    x = classifier_input
    for layer_name in classifier_layer_names:
        x = model.get_layer(layer_name)(x)
    classifier_model = Model(classifier_input, x)

    img_array = np.expand_dims(tile, axis=0)
    #img_array = tf.convert_to_tensor(img_array, dtype=tf.float32)

    # Then, we compute the gradient of the top predicted class for our input image
    # with respect to the activations of the last conv layer
    with tf.GradientTape() as tape:
        # Compute activations of the last conv layer and make the tape watch it
        last_conv_layer_output = last_conv_layer_model(img_array)
        tape.watch(last_conv_layer_output)
        # Compute class predictions
        preds = classifier_model(last_conv_layer_output)
        top_pred_index = tf.argmax(preds[0])
        top_class_channel = preds[:, tf.cast(top_pred_index, dtype=tf.int32)]

    # This is the gradient of the top predicted class with regard to
    # the output feature map of the last conv layer
    grads = tape.gradient(top_class_channel, last_conv_layer_output)

    # This is a vector where each entry is the mean intensity of the gradient
    # over a specific feature map channel
    pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))

    # We multiply each channel in the feature map array
    # by "how important this channel is" with regard to the top predicted class
    last_conv_layer_output = last_conv_layer_output.numpy()[0]
    pooled_grads = pooled_grads.numpy()
    for i in range(pooled_grads.shape[-1]):
        last_conv_layer_output[:, :, i] *= pooled_grads[i]

    # The channel-wise mean of the resulting feature map
    # is our heatmap of class activation
    heatmap = np.mean(last_conv_layer_output, axis=-1)

    # For visualization purpose, we will also normalize the heatmap between 0 & 1
    heatmap = np.maximum(heatmap, 0) / np.max(heatmap)
    return heatmap




def make_heatmap(cam, top_pred):
    """
    Generate a heatmap image from a heatmap tensor.

    :param cam: class activation map tensor.
    :param top_pred: tells whether the class has highest support for this tile.
    :return: a false-colored heatmap (``AmfConfig.get('colormap')``).
    """

    # Resize the heatmap to input tile size.
    edge = AmfConfig.get('tile_edge')
    heatmap = cv2.resize(cam.numpy(), (edge, edge))

    # Normalize heatmap values.
    numer = heatmap - np.min(heatmap)
    denom = heatmap.max() - heatmap.min() + 1e-10 # division by zero
    heatmap = numer / denom
    
    # Convert raw values to 8-bit pixel intensities.
    heatmap = (heatmap * 255).astype('uint8')

    # Apply colormap.
    colormap = AmfConfig.get('colormap') if top_pred else cv2.COLORMAP_BONE
    color_heatmap = cv2.applyColorMap(heatmap, colormap)

    return color_heatmap



def process_tile(model, classifier_layer_names, mosaics, tile, r, c):

    # Generate class activation maps for all annotations classes
    # The function <compute_cam> returns a boolean which indicates
    # whether the given class is the best match.
    cams = [compute_cam(model, classifier_layer_names, tile)]

    edge = edge = AmfConfig.get('tile_edge')

    for cam in cams:

        # Generats the heatmap.
        heatmap = make_heatmap(cam, True)

        # Resize the tile to its original size, desaturate
        # and increase the contrast (better overlay rendition).
        resized = np.uint8(cv2.resize(tile, (edge, edge)) * 255)
        #resized = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
        #resized = cv2.cvtColor(resized, cv2.COLOR_GRAY2BGR)
        #resized = cv2.convertScaleAbs(resized, alpha=1.5, beta=0.8)

        # Overlay the heatmap on top of the desaturated tile.
        output = cv2.addWeighted(heatmap, 0.4, resized, 0.6, 0.0)
        output = cv2.cvtColor(output, cv2.COLOR_BGR2RGB)
        
        # Inserts the overlay on the large map.
        rpos = r
        cpos = c
        mosaics[rpos:rpos + edge, cpos:cpos + edge] = output    



def generate(mosaics, model, row, input_data):
    """
    Generate a mosaic of class activation maps for an array of tiles.

    :param model: pre-trained model used for predictions.
    :param row: row of preprocessed tiles from the large input image.
    :param r: row index.
    """

    if AmfConfig.get('generate_cams'):       
        
        if AmfConfig.colonization():
               
            classifier_layer_names = ['M4', 'F', 'FCRS1', 'DRS1', 
                                      'FCRS2', 'DRS2', 'RS']
               
            for c, tile in enumerate(row):
            
                process_tile(model, classifier_layer_names, mosaics, tile,
                             input_data, c)

        else:
        
                print('Not yet implemented')

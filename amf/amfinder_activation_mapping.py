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



def get_conv_model(model):
    """
    Map the model input to its last convolutional layer.

    PARAMETER
        - model: Pre-trained model used for predictions.
    
    Returns the last convolutional layer (`last_conv`) of the input model,
    and a fresh model mapping `model` input to `last_conv` output.
    """

    # The last convolutional layer occurs first on the reversed layer list.
    for layer in reversed(model.layers):

        if isinstance(layer, Conv2D):

            last_conv = layer
            conv_model = Model(model.inputs, last_conv.output)

            return (last_conv, conv_model)

    # We could not find any convolutional layer in the input model.
    AmfLog.failwith(f'{model} has no Conv2D layer', AmfLog.ERR_INVALID_MODEL)



def get_classifier_model(model, last_conv):
    """
    Map the output of the last convolutional layer to model predictions.

    :param model: pre-trained model used for predictions.
    :param last_conv: last convolutional layer of ``model``.
    """

    classifier_input = Input(shape=last_conv.output.shape[1:])
    x = classifier_input

    # Index of the last convolutional layer.
    last_index = model.layers.index(last_conv)   
    
    for layer in model.layers[last_index + 1:]:

        x = layer(x)
    
    return Model(classifier_input, x)



def compute_cam(index, tile, conv_model, classifier):
    """
    Compute gradient and class activation map.

    :param index: class index.
    :param tile: input tile to be processed.
    :param conv_model:  model to retrieve the output of the last Conv2D layer.
    :param classifier:  model to retrieve the gradients.
    :return: the tile activation map for the given class, and a boolean which
    indicates whether the class has highest support for the given tile.
    """

    # Transform the tile array into a batch.
    # <tile_batch> shape is (1, model_input_size, model_input_size, 3).
    tile_batch = np.expand_dims(tile, axis=0)
    tile_batch = tf.convert_to_tensor(tile_batch, dtype=tf.float32)

    # Compute the output of the last convolutional layer.
    last_conv_output = conv_model(tile_batch)

    with tf.GradientTape(watch_accessed_variables=False) as tape:

        # Watch the gradient.
        tape.watch(last_conv_output)

        # Obtain the predictions.
        predictions = classifier(last_conv_output)

        # Build a tensor for the given index
        class_index = tf.convert_to_tensor(index, dtype='int64') 

        # Dtermine whether the index corresponds to the best prediction.
        is_best_match = class_index == tf.argmax(predictions[0])

        # Retrieve the corresponding channel.
        class_channel = predictions[:, class_index]

    # Retrieve the corresponding gradients.
    grads = tape.gradient(class_channel, last_conv_output)

    # Compute the guided gradients.
    cast_conv_outputs = tf.cast(last_conv_output > 0, 'float32')
    cast_grads = tf.cast(grads > 0, 'float32')
    guided_grads = cast_conv_outputs * cast_grads * grads

    # Remove the unnecessary batch dimension from the convolution 
    # and from the guided gradients.
    last_conv_output = last_conv_output[0]
    guided_grads = guided_grads[0]

    # Compute the average of the gradient values, and, using them
    # as weights, compute the ponderation of the filters with
    # respect to the weights.
    weights = tf.reduce_mean(guided_grads, axis=(0, 1))
    cam = tf.reduce_sum(tf.multiply(weights, last_conv_output), axis=-1)

    return (cam, is_best_match)



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



def process_tile(conv_model, classifier_model, mosaics, edge, r, c, tile):

    # Generate class activation maps for all annotations classes
    # The function <compute_cam> returns a boolean which indicates
    # whether the given class is the best match.
    cams = [compute_cam(i, tile, conv_model, classifier_model)
            for i, _ in enumerate(AmfConfig.get('header'))]


    for (cam, is_best_match), mosaic in zip(cams, mosaics):

        # Generats the heatmap.
        heatmap = make_heatmap(cam, is_best_match)

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
        mosaic[rpos:rpos + edge, cpos:cpos + edge] = output    



def generate(mosaics, model, row, input_data):
    """
    Generate a mosaic of class activation maps for an array of tiles.

    :param model: pre-trained model used for predictions.
    :param row: row of preprocessed tiles from the large input image.
    :param r: row index.
    """

    if AmfConfig.get('generate_cams'):

        edge = AmfConfig.get('tile_edge')

        # Map the input tile to the activations of the last Conv2D layer.
        last_conv, conv_model = get_conv_model(model)

        # Map the activations of <last_conv> to the final class predictions.
        classifier_model = get_classifier_model(model, last_conv)
        
        if AmfConfig.colonization():
               
            for c, tile in enumerate(row):
            
                process_tile(conv_model, classifier_model, mosaics, edge,
                             input_data, c, tile)

        else:
        
            for x, tile in zip(input_data, row):
       
                process_tile(conv_model, classifier_model, mosaics, edge,
                             x[0], x[1], tile)
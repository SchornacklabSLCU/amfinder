# CastANet - castanet_activation_mapping.py

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

import castanet_config as cConfig

MAPS = []
INVALID_MODEL = 40



def initialize(model, nrows, ncols):
    """ Initializes the class activation map. """

    if cConfig.get('generate_cams'):

        global MAPS
        edge = cConfig.get('tile_edge')
        blank = np.zeros((nrows * edge, ncols * edge, 3), np.uint8)
        MAPS = [ blank.copy() for _ in cConfig.get('header')]
        del blank



def get_last_conv_model(model):
    """ Builds a model that connect to the last Conv2D layer. """

    # Uses list reversal. The first Conv2D layer is the last
    # to occur in the given model.
    for layer in reversed(model.layers):

        if isinstance(layer, Conv2D):

            last_conv = layer
            return last_conv, Model(model.inputs, last_conv.output)

    print(f'{model} has no Conv2D layer.')
    sys.exit(INVALID_MODEL)



def get_classifier_model(model, last_conv):
    """ Builds a classifier model that connects the last layer output
        to the successive dense layers and final class predictions. """
    classifier_input = Input(shape=last_conv.output.shape[1:])
    x = classifier_input

    ok = False # skips all layers until after the last Conv2D.
    for layer in model.layers:
        if ok: x = layer(x)
        if layer.name == last_conv.name: ok = True
    
    return Model(classifier_input, x)



def compute_cam(index, tile, last_conv_model, classifier_model):
    """ """

    # We add a dimension to transform our array into a batch
    # of size (1, model_input_size, model_input_size, 3)
    tile_batch = np.expand_dims(tile, axis=0)

    # Compute the last layer output values.
    last_conv_output = last_conv_model(tile_batch)

    with tf.GradientTape() as tape:

        # Start watching the gradient.
        tape.watch(last_conv_output)

        # Obtain the predictions.
        predictions = classifier_model(last_conv_output)

        # Builds a tensor class index from a given index,
        # and determines whether this is the main activation class.
        class_index = tf.convert_to_tensor(index, dtype='int64') 
        is_best_match = class_index == tf.argmax(predictions[0])

        # Retrieves the corresponding channel.
        class_channel = predictions[:, class_index]

    # Retrieves the corresponding gradients.
    grads = tape.gradient(class_channel, last_conv_output)

    # Compute the guided gradients.
    cast_conv_outputs = tf.cast(last_conv_output > 0, 'float32')
    cast_grads = tf.cast(grads > 0, 'float32')
    guided_grads = cast_conv_outputs * cast_grads * grads

    # The convolution and guided gradients have a batch dimension
    # (which we don't need) so let's grab the volume itself.
    last_conv_output = last_conv_output[0]
    guided_grads = guided_grads[0]

    # Compute the average of the gradient values, and using them
    # as weights, compute the ponderation of the filters with
    # respect to the weights.
    weights = tf.reduce_mean(guided_grads, axis=(0, 1))
    cam = tf.reduce_sum(tf.multiply(weights, last_conv_output), axis=-1)

    return (cam, is_best_match)



def make_heatmap(cam, is_best_match, epsilon=1e-10):
    """ """

    # Resizes the heatmap to input tile size.
    edge = cConfig.get('tile_edge')
    heatmap = cv2.resize(cam.numpy(), (edge, edge))

    # Normalizes heatmap values.
    numer = heatmap - np.min(heatmap)
    denom = heatmap.max() - heatmap.min() + epsilon
    heatmap = numer / denom
    
    # Converts raw values to 8-bit pixel intensities.
    heatmap = (heatmap * 255).astype('uint8')

    # Applies colormap.
    colormap = cv2.COLORMAP_JET if is_best_match else cv2.COLORMAP_BONE
    return cv2.applyColorMap(heatmap, colormap)



# Grad-CAM class activation visualization.
def generate(model, row, r):
    """ """

    if cConfig.get('generate_cams'):

        edge = cConfig.get('tile_edge')

        # Maps the input tile to the activations of the last Conv2D layer.
        last_conv, last_conv_model = get_last_conv_model(model)

        # Maps the activations of <last_conv> to the final class predictions.
        classifier_model = get_classifier_model(model, last_conv)
        
        for c, tile in enumerate(row):

            # Generate class activation maps for all annotations classes
            # The function <compute_cam> returns a boolean which indicates
            # whether the given class is the best match.    
            cams = [compute_cam(i, tile, last_conv_model, classifier_model)
                    for i, _ in enumerate(cConfig.get('header'))]
        

            for (cam, is_best_match), large_map in zip(cams, MAPS):

                # Generates the heatmap.
                heatmap = make_heatmap(cam, is_best_match)

                # Converts the tile to greyscale.
                resized = np.uint8(cv2.resize(tile, (edge, edge)) * 255)
                resized = cv2.cvtColor(resized, cv2.COLOR_RGB2GRAY)
                resized = cv2.cvtColor(resized, cv2.COLOR_GRAY2BGR)

                # Overlay the heatmap on the tile.
                output = np.zeros((edge, edge, 3), np.uint8)
                output = cv2.addWeighted(heatmap, 0.4, resized, 0.6, 0.0)
                output = cv2.cvtColor(output, cv2.COLOR_BGR2RGB)
                
                # Inserts the overlay on the large map.
                rpos = r * edge
                cpos = c * edge
                large_map[rpos:rpos + edge, cpos:cpos + edge] = output           



def finalize():
    """ """

    return MAPS if cConfig.get('generate_cams') else None

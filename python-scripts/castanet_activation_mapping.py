# CastANet - castanet_activation_mapping.py

import cv2
import cmapy
import keras
import matplotlib
import numpy as np
import tensorflow as tf
from keras import Model
from keras.layers import Conv2D
from keras.layers import Dense

import castanet_config as cConfig

MAP = None
INVALID_MODEL = 40



def initialize(model, nrows, ncols):
    """ Initializes the class activation map. """

    global MAP
    edge = cConfig.get('tile_edge')
    MAP = np.zeros((nrows * edge, ncols * edge, 3), np.uint8)



def get_last_layer_model(model):
    """ Builds a model that connect to the last Conv2D layer. """

    # Uses list reversal. The first Conv2D layer is the last
    # to occur in the given model.
    for layer in model.layers[::-1]:
        if isinstance(layer, Conv2D):
            last_layer = layer
            last_layer_model = Model(model.inputs, last_layer.output)
            return last_layer, last_layer_model 

    # A model cannot lack Conv2D layers!
    sys.exit(INVALID_MODEL)



def get_classifier_model(model, last_layer):
    """ Builds a classifier model that connects the last layer output
        to the successive dense layers and final class predictions. """
    classifier_input = keras.Input(shape=last_layer.output.shape[1:])
    x = classifier_input

    ok = False # skips all layers until after the last Conv2D.
    for layer in model.layers:
        if ok: x = layer(x)
        if layer.name == last_layer.name: ok = True
    
    return Model(classifier_input, x)



# Grad-CAM class activation visualization.
def generate(model, row, r):
    """ """

    edge = cConfig.get('tile_edge')

    # Maps the input tile to the activations of the last Conv2D layer.
    last_layer, last_layer_model = get_last_layer_model(model)

    # Maps the activations of <last_layer> to the final class predictions.
    classifier_model = get_classifier_model(model, last_layer)
    
    c = 0
    for tile in row:

        # We add a dimension to transform our array into a batch
        # of size (1, model_input_size, model_input_size, 3)
        tile_batch = np.expand_dims(tile, axis=0)

        with tf.GradientTape() as tape:
            # Compute the last layer output values.
            last_layer_output = last_layer_model(tile_batch)
            # Start watching the gradient.
            tape.watch(last_layer_output)
            # Obtain the predictions.
            preds = classifier_model(last_layer_output)
            # Get the top prediction class.
            top_pred_index = tf.argmax(preds[0])
            # Retrieves the corresponding channel.
            top_class_channel = preds[:, top_pred_index]
            # Retrieve the gradient corresponding to the top prediction class.
            grads = tape.gradient(top_class_channel, last_layer_output)
            # Computes the weights.
            pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))

        last_layer_output = last_layer_output.numpy()[0]
        pooled_grads = pooled_grads.numpy()
        # 
        for i in range(pooled_grads.shape[-1]):
            last_layer_output[:, :, i] *= pooled_grads[i]
        
        heatmap = np.mean(last_layer_output, axis=-1)
        heatmap = heatmap / (np.max(heatmap) + 1e-100)
        heatmap = cv2.resize(heatmap, (edge, edge))
        heatmap = np.uint8(heatmap * 255)
        heatmap = cv2.applyColorMap(heatmap, cv2.COLORMAP_COOL)
        resized = np.uint8(cv2.resize(tile, (edge, edge)) * 255)
        output = np.zeros((edge, edge, 3), np.uint8)
        output = cv2.addWeighted(heatmap, 0.7, resized, 0.3, 0.0)
        l_img = MAPPING['image']
        rpos = r * edge
        cpos = c * edge
        l_img[rpos:rpos + edge, cpos:cpos + edge] = output
        c += 1



def finalize():

    matplotlib.image.imsave('map.png',  MAPPING['image'])
    



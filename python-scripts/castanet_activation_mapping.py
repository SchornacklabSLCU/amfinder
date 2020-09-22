# CastANet - castanet_activation_mapping.py

import keras.backend as kb

import castanet_config as cConfig


MAPPING = {
    'layer': None,
    'shape': None,
    'gradients': None,
    'pooled': None,
    'iterate': None
}



def initialize(model):
    """ Retrieves the gradient information that will be used to
        compute the activation maps. """

    #
    layer = model.get_layer('C8')
    MAPPING['layer'] = layer

    #
    MAPPING['shape'] = layer.output.shape[3]

    # Retrieves the gradient values.
    gradients = kb.gradients(model.output, layer.output)[0]
    MAPPING['gradients'] = gradients

    # Each entry of the tensor <pooled> is the mean intensity of the
    # gradient over a specific feature map channel. 
    pooled = kb.mean(gradients, axis=(0, 1, 2))
    MAPPING['pooled'] = pooled

    # Access the values of the quantities we just defined.
    MAPPING['iterate'] = kb.function([model.input], [pooled, layer.output[0]])



def generate(model, row):
    """ """



#label = Mycorrhiza.get_label(str(index))
#long_descr = Mycorrhiza.get_long_descr(label)
#Logger.info('Image "{}", tile R{}C{}: activation map for '
#            'class {} ({}).'.format(base, r, c, label, long_descr))
#output = model.output[index]
## Retrieve all convolutional layers, then grab the last one.
#last_conv_layer = ConvNet.get_last_conv_layer(model)
#n_channels = last_conv_layer.output.shape[3]
#grads = K.gradients(output, last_conv_layer.output)[0]
#pooled_grads = K.mean(grads, axis=(0, 1, 2))
#iterate = K.function([model.input], [pooled_grads,
#                                     last_conv_layer.output[0]])
#x = ConvNet.preprocess_input([Image.load_tile(image, r, c)])
#pooled_grads_value, conv_layer_output_value = iterate([x])
#for i in range(n_channels):
#    conv_layer_output_value[:, :, i] *= pooled_grads_value[i]
#heatmap = np.mean(conv_layer_output_value, axis=-1)
#heatmap = np.maximum(heatmap, 0) # ensure there is no negative value.
#max = np.max(heatmap)
#if max: heatmap /= max # to prevent division by zero.
#tile = Image.load_tile(image, r, c, display_mode=True, grayscale=True)
#Logger.info('Tile is {}.'.format(type(tile)))
#width, height = tile.size
#heatmap = cv2.resize(heatmap, (width, height))
#heatmap = np.uint8(255 * heatmap)
#heatmap = cv2.applyColorMap(heatmap, cmapy.cmap(COLORMAP))
#superimposed_img = heatmap * HIF + tile
#filename = '{}_R{}C{}_class_{}.jpg'.format(base, r, c, label)
#cv2.imwrite(filename, superimposed_img)
#return filename


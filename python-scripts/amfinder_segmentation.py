# AMFinder - amfinder_segmentation.py

import random
import pyvips
import functools
import numpy as np

import amfinder_config as cConfig

# Interpolation mode, optimized for speed.
INTERP_NEAREST = pyvips.vinterpolate.Interpolate.new('nearest')

def tile(image, r, c):
    """ Extracts a tile from a large image, resizes it to
        model input size, and returns it as a numpy array. """

    # Retrieves an individual tile.
    edge = cConfig.get('tile_edge')
    tile = image.crop(c * edge, r * edge, edge, edge)

    # Resizes to N x N pixels, N = 126 = cConfig.get('model_input_size')
    ratio = cConfig.get('model_input_size') / edge
    resized = tile.resize(ratio, interpolate=INTERP_NEAREST)

    # Returns as numpy array.
    return np.ndarray(buffer=resized.write_to_memory(),
                      dtype=np.uint8,
                      shape=[resized.height, resized.width, resized.bands])

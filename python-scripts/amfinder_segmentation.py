# CastANet - amfinder_segmentation.py

import random
import pyvips
import functools
import numpy as np

import amfinder_config as cConfig

INTERP_NEAREST = pyvips.vinterpolate.Interpolate.new('nearest')



def tile(image, r, c):
    """ Extracts a tile from a large image, resizes it to
        model input size, and returns it as a NumPy array. """

    edge = cConfig.get('tile_edge')

    tile = image.crop(c * edge, r * edge, edge, edge)
    tile = tile.resize(cConfig.get('model_input_size') / edge,
                       interpolate=INTERP_NEAREST)

    return np.ndarray(buffer=tile.write_to_memory(),
                      dtype=np.uint8,
                      shape=[tile.height, tile.width, tile.bands])

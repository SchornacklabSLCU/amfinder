# AMFinder - amfinder_segmentation.py

""" Image Segmentation.

    Returns tiles of a large input image.
    
    Constants
    -----------
    INTERPOLATION - Interpolation mode for image resizing.

    Functions
    ------------
    tile - crops a tile at the given coordinates within a large input image.
"""

import pyvips
import numpy as np

import amfinder_model as AmfModel
import amfinder_config as AmfConfig



# Not the best quality, but optimized for speed.
INTERPOLATION = pyvips.vinterpolate.Interpolate.new('nearest')



def tile(image, r, c):
    """ Extracts a tile from a large image, resizes it to
        model input size, and returns it as a numpy array. """

    edge = AmfConfig.get('tile_edge')
    tile = image.crop(c * edge, r * edge, edge, edge)

    ratio = AmfModel.INPUT_SIZE / edge
    resized = tile.resize(ratio, interpolate=INTERPOLATION)

    return np.ndarray(buffer=resized.write_to_memory(),
                      dtype=np.uint8,
                      shape=[resized.height, resized.width, resized.bands])

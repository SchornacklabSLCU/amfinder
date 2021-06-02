# AMFinder - amfinder_segmentation.py
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
Image Segmentation.

Crop tiles (squares) and apply diverse image modifications.

Constants
-----------
INTERPOLATION - Interpolation mode for image resizing.

Functions
------------
:function tile: Extracts a tile from a large image.
:function preprocess: Convert a tile list to NumPy array and normalise pixels.
"""

import pyvips
import random
random.seed(42)
import numpy as np

import amfinder_model as AmfModel
import amfinder_config as AmfConfig



# Not the best quality, but optimized for speed.
# To check availability, type in a terminal: vips -l interpolate
INTERPOLATION = pyvips.vinterpolate.Interpolate.new('nearest')



def load(image_path, access='random'):
    """
    Loads an image using the vips library.
    """

    return pyvips.Image.new_from_file(image_path, access=access)



def tile(image, r, c, edge=None):
    """
    Extracts a tile from a large image, resizes it to
    the required CNN input image size, and applies
    data augmentation (if actve).

    :param image: The source image used to extract tiles.
    :param r: The row index of the tile to extract.
    :param c: The column index of the tile to extract.
    :return: Set of tile, converted to numpy arrays.
    :rtype: list
    """

    edge = edge if edge is not None else AmfConfig.get('tile_edge')
    tile = image.crop(c * edge, r * edge, edge, edge)

    # In super-resolution mode, ensure the tile is 42x42 pixels.
    if AmfConfig.get('super_resolution'):
      
        if edge != 42:
        
            ratio = 42 / edge
            tile = tile.resize(ratio, interpolate=INTERPOLATION)
    
    # Otherwise, use interpolation to bring tile to 126x126 pixels.
    elif AmfModel.INPUT_SIZE != edge:

        ratio = AmfModel.INPUT_SIZE / edge
        tile = tile.resize(ratio, interpolate=INTERPOLATION)

    return np.ndarray(buffer=tile.write_to_memory(),
                      dtype=np.uint8,
                      shape=[tile.height, tile.width, tile.bands])



def preprocess(tile_list):
    """
    Preprocess a list of tiles.
    
    :param tile_list: list of tiles extracted using the function above.
    :return: a numpy array containing normalised pixel values for several tiles.
    :rtype: numpy.ndarray
    """
    
    return np.array(tile_list, np.float32) / 255.0



def mosaic(image, edge=None):

    edge = edge if edge is not None else AmfConfig.get('tile_edge')

    nrows = int(image.height // edge)
    ncols = int(image.width // edge)

    if nrows == 0 or ncols == 0:

        AmfLog.warning('Tile size ({edge} pixels) is too large')
        return None
        
    else:

        tiles = []

        for r in range(nrows):

            for c in range(ncols):
 
                tiles.append(tile(image, r, c, edge))

        return tiles


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
:function data_augmentation: Non-destructive tile augmentation.
:function tile: Extracts a tile from a large image.
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



def data_augmentation(tile):
    """
    Non-destructive tile augmentation. Fungal structures may occur
    on the edges, therefore random rotations and zoomed in are not
    used in this function.
    
    :param tile: The tile to modify.
    :return: List containing both the original tile and the modified versions.
    :rtype: list
    """

    tile_list = [tile]

    # Rotation
    tile_list.append(tile.rotate(90))

    # Chroma and hue.
    c = random.uniform(0.5, 1.5)
    h = random.uniform(0.5, 1.5)
    tile_list.append(tile.colourspace('lch') * [1, c, h])
    
    # Brightness.
    tile_list.append(tile * random.uniform(0.2, 1.5))
  
    # Grayscale tile.
    tile_list.append(tile.colourspace('b-w'))

    # Complementary colors.
    tile_list.append(tile.invert())
                                   
    # Gaussian blur. 
    tile_list.append(tile.gaussblur(random.uniform(0.5, 2.5)))
                                       
    return [tile.colourspace('srgb') for tile in tile_list]



def tile(image, r, c):
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

    edge = AmfConfig.get('tile_edge')
    tile = image.crop(c * edge, r * edge, edge, edge)

    if AmfModel.INPUT_SIZE != edge:

        ratio = AmfModel.INPUT_SIZE / edge
        tile = tile.resize(ratio, interpolate=INTERPOLATION)

    tile_list = [tile]

    # Perform various types of data augmentation (grayscale, hue, blur)
    if AmfConfig.get('run_mode') == 'train' and AmfConfig.get('data_augm'):
      
        tile_list = data_augmentation(tile)

    # DEBUG: save tiles as JPEG files.
    #for i, t in enumerate(tile_list):
    #    t.jpegsave("tile_%.5f.jpg" % (random.uniform(0,2)))

    data = [np.ndarray(buffer=tile.write_to_memory(),
                       dtype=np.uint8,
                       shape=[tile.height, tile.width, tile.bands])
            for tile in tile_list]

    return data

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

""" Image Segmentation.

    Returns tiles of a large input image.
    
    Constants
    -----------
    INTERPOLATION - Interpolation mode for image resizing.

    Functions
    ------------
    tile - crops a tile at the given coordinates within a large input image.
    print_memory_usage - prints total memory usage.
"""

import os
import sys
import pyvips
import random
random.seed(42)
import numpy as np
import psutil

import amfinder_model as AmfModel
import amfinder_config as AmfConfig



# Not the best quality, but optimized for speed.
INTERPOLATION = pyvips.vinterpolate.Interpolate.new('nearest')



def tile(image, r, c):
    """ Extracts a tile from a large image, resizes it to
        model input size, and returns it as a numpy array. """

    edge = AmfConfig.get('tile_edge')
    tile = image.crop(c * edge, r * edge, edge, edge)

    if AmfModel.INPUT_SIZE != edge:

        ratio = AmfModel.INPUT_SIZE / edge
        tile = tile.resize(ratio, interpolate=INTERPOLATION)

    # perform various types of data augmentation (grayscale, hue, blur)
    if AmfConfig.get('run_mode') == 'train':

        tmp = tile

        # Changes chroma and hue.
        if random.uniform(0, 100) < 50:

            tmp = tile.colourspace("lch") * [1,
                                             random.uniform(0.5, 1.5),
                                             random.uniform(0.5, 1.5)]
                          
        # turn to grayscale.                   
        elif random.uniform(0, 100) < 50:

            tmp = tile.colourspace("b-w")

        # Negative.
        elif  random.uniform(0, 100) < 50:

            tmp = tile.invert()
                                            
        tile = tmp.colourspace("srgb")

    # Debug only, in case we want to have a look at tiles.
    # tile.jpegsave("tile_%.5f.jpg" % (random.uniform(0,2)))

    data = np.ndarray(buffer=tile.write_to_memory(),
                      dtype=np.uint8,
                      shape=[tile.height, tile.width, tile.bands])

    # Add 90 degrees rotations to some tiles. We do not use
    # other angle values to make sure no structure is lost.
    # This will be combined with tile flipping by the image
    # generator (see amfinder_train.py).
    if AmfConfig.get('run_mode') == 'train' and random.uniform(0, 100) < 50:

        data = np.rot90(data)
        

    return data



def print_memory_usage():
    """ Prints amf memory usage. """

    process = psutil.Process(os.getpid())
    mb = process.memory_info().rss / (1024 * 1024)
    print(f"* Total memory used: {mb} Mb.")

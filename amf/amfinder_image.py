# AMFinder - amfinder_image.py
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
Image modifications for the purpose of data augmentation.
Adapted from https://www.degeneratestate.org/posts/2016/Oct/23/image-processing-with-numpy/


Functions
------------
:function invert: invert colours.
:function grayscale: convert an image to grayscale.
:function rotate_colours: transform colours.

"""

import random
random.seed(42)
import numpy as np
from scipy.ndimage import median_filter



def invert(tile):
    """
    Image inversion.
    """
    return 255 - tile



def grayscale(tile):
    """
    Converts the input image to grayscale.
    """

    gray = np.dot(tile[...,:3], [0.2989, 0.5870, 0.1140])
    return np.stack((gray,) * 3, axis=-1)



def do_normalise(tile):

    return -np.log(1/((1 + tile)/257) - 1)



def undo_normalise(tile):

    return (1 + 1/(np.exp(-tile) + 1) * 257)



def rotation_matrix(theta):
    """
    3D rotation matrix around the X-axis by angle theta
    """
   
    return np.c_[
        [1,0,0],
        [0,np.cos(theta),-np.sin(theta)],
        [0,np.sin(theta),np.cos(theta)]
    ]



def rotate_colours(tile):
    """
    Rotate the color wheels, resulting in altered hue.
    """
    norm = do_normalise(tile)
    theta = random.randint(0, 20) * np.pi / 10
    print(theta)
    norm_rot = np.einsum("ijk,lk->ijl", norm, rotation_matrix(theta))
    return undo_normalise(norm_rot)



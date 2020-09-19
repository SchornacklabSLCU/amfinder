# CastANet - castanet_segmentation.py

import random
import pyvips
import numpy as np

import castanet_config as cConfig

INTERP_NEAREST = pyvips.vinterpolate.Interpolate.new('nearest')



def tile(image, r, c):
    """ Extracts a tile from a large image, resizes it to
        model input size, and returns it as a NumPy array. """

    edge = cConfig.get('tile_edge')
    tile = image.crop(c * edge, r * edge, edge, edge)
    scale = cConfig.get('model_input_size') / edge
    tile = tile.resize(scale, interpolate=INTERP_NEAREST)

    buffer = tile.write_to_memory()
    return np.ndarray(buffer=buffer, dtype=np.uint8,
                      shape=[tile.height, tile.width, tile.bands])



def drop_background(tiles, hot_labels):
    """Build training dataset, possibly removing some background images"""
    i = 0
    col = 0
    ncol = 0
    bg_count = 0
    bg_dismiss = 0
    x_train_list = []
    y_train_list = []
    for tile, tag in tiles.values:
        label = hot_labels[i]
        i += 1
        if label[0] == 1:
          col += 1
        elif label[1] == 1:
          ncol += 1
        else :
            bg_count += 1
            if random.uniform(0, 100) <= CConfig.drop_background():
                bg_dismiss += 1
                continue
        x_train_list.append(tile)
        y_train_list.append(label)
    print('    - Colonized: {}'.format(col))
    print('    - Non-colonized: {}'.format(ncol))
    print('    - Background: {}'.format(bg_count - bg_dismiss))
    return (x_train_list, y_train_list)

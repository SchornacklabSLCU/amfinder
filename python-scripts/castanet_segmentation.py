# CastANet - castanet_segmentation.py

import castanet_config as CFG
from keras.preprocessing import image as keras_image

def tile(image, r, c):
  src_edge = CFG.get('source_tile_edge')
  out_edge = CFG.get('output_tile_edge')
  c *= src_edge
  r *= src_edge
  s = (c, r, c + src_edge, r + src_edge)
  if s[0] < 0 or s[1] < 0 or s[2] > image.width or s[3] > image.height:
    return None
  else:
    tile = image.crop(s)
    return keras_image.img_to_array(tile.resize((out_edge, out_edge)))


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

# CastANet - castanet_predict.py

import os
import numpy as np
import pandas as pd
import castanet_config as cfg
import castanet_segmentation as segm
from keras.preprocessing import image as keras_image

XY = ['row', 'col']

def get_input_rows(image, tile_count_w, tile_count_h):
  row_index = []
  col_lists = []
  tile_lists = []
  for row in range(tile_count_h): # iter rows.
    this_row_list = []
    this_col_index_list = list(range(tile_count_w))
    for col in range(tile_count_w): # iter columns.
      curr = segm.tile(image, row, col)
      if curr is None:
        this_col_index_list.remove(col)
        continue
      else:
        this_row_list.append(curr)
    if len(this_col_index_list) == 0: # nothing to keep!
      continue
    else:
      row_index.append(row)
      col_lists.append(this_col_index_list)
      preprocess = lambda x: x / 255.0
      tmp_list = preprocess(np.array(this_row_list, np.float32))
      tile_lists.append(tmp_list)
  return (row_index, col_lists, tile_lists)


def save(data, img_path):
  base = os.path.splitext(img_path)[0]
  path = '{}.autotags.tsv'.format(base)
  data.to_csv(path, sep='\t', encoding='utf-8', index=False)


def predict(cnn, img_path, image, row_index, col_lists, tile_lists):
  data = []
  for row, cols, tiles in zip(row_index, col_lists, tile_lists):
    annot = cnn.predict(tiles, batch_size=cfg.get('batch_size'), verbose=0)
    annot = [x.reshape(x.shape[0]) for x in annot]   
    annot = np.array(annot)
    annot = pd.DataFrame(annot)
    annot.insert(0, column=XY[1], value=cols)
    annot.insert(0, column=XY[0], value=[row]*len(cols))
    data.append(annot)

  data = pd.concat(data, ignore_index=True)
  data.columns = XY + cfg.get('header')
  save(data, img_path)


def run(cnn, input_files):
    for img_path in input_files:
      name = os.path.basename(img_path)
      print('* Predicting annotations for "{}"'.format(name))
      image = keras_image.load_img(img_path, color_mode='rgb', target_size=None)
      edge = cfg.get('source_tile_edge')
      tile_count_w = image.width // edge
      tile_count_h = image.height // edge
      row_index, col_lists, tile_lists = get_input_rows(image, tile_count_w,
                                                        tile_count_h)
      predict(cnn, img_path, image, row_index, col_lists, tile_lists)




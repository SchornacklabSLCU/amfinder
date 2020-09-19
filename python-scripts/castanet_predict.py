# CastANet - castanet_predict.py

import os
import numpy as np
import pandas as pd
from keras.preprocessing import image as keras_image

import castanet_config as cConfig
import castanet_segmentation as cSegm


XY = ['row', 'col']

def get_input_rows(image, tile_count_w, tile_count_h):
  row_index = []
  col_lists = []
  tile_lists = []
  for row in range(tile_count_h): # iter rows.
    this_row_list = []
    this_col_index_list = list(range(tile_count_w))
    for col in range(tile_count_w): # iter columns.
      curr = cSegm.tile(image, row, col)
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



def make_table(cnn, tiles):
  """ This function creates a prediction table by iterating a list
      of Numpy arrays containing tiles for each row. """
  nrows = len(tiles)
  if nrows == 0:
    return None
  else:
    bs = cConfig.get('batch_size')
    results = [pd.DataFrame(cnn.predict(t, batch_size=bs)) for t in tiles]
    # Generates the final table.
    table = pd.concat(results, ignore_index=True)
    table.columns = cConfig.get('header')   
    # Inserts row and column indexes.
    ncols = len(results[0])
    col_values = list(range(ncols)) * nrows
    row_values = [x // ncols for x in range(nrows * ncols)]
    table.insert(0, column='col', value=col_values)
    table.insert(0, column='row', value=row_values)
    return table



def run(cnn, input_files):
    for img_path in input_files:
      name = os.path.basename(img_path)
      print('* Predicting annotations for "{}"'.format(name))
      image = keras_image.load_img(img_path, color_mode='rgb', target_size=None)
      edge = cConfig.get('tile_edge')
      tile_count_w = image.width // edge
      tile_count_h = image.height // edge
      row_index, col_lists, tile_lists = get_input_rows(image, tile_count_w,
                                                        tile_count_h)
      ncols = len(col_lists[0])
      print(type(tile_lists[0]))
      table = make_table(cnn, tile_lists)
      print(table.head(32))
      #save(table, img_path)



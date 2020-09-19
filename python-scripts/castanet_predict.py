# CastANet - castanet_predict.py

import os
import numpy as np
import pandas as pd
from keras.preprocessing import image as keras_image

import castanet_save as cSave
import castanet_config as cConfig
import castanet_segmentation as cSegm



def get_tile_arrays(image):
  """ This functions builds numpy arrays containing all tiles of
      the same row. These tables are then used for predictions. """
  # Determines the number of tiles per row or column.
  edge = cConfig.get('tile_edge')
  r_range = range(image.height // edge)
  c_range = range(image.width // edge)
  # Extracts all tiles from the input image.
  tiles = [[cSegm.tile(image, r, c) for c in c_range] for r in r_range]
  # Converts inner lists to numpy arrays and normalizes pixel values.
  return [np.array(t, np.float32) / 255.0 for t in tiles]



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
  """ For each image given as input, performs segmentation into tiles
      and predicts mycorrhizal structures. The final table is then 
      saved as ZIP archive in the same location as the input image. """
  for path in input_files:
    name = os.path.basename(path)
    print('* Predicting mycorrhizal structures on "{}"'.format(name))
    image = keras_image.load_img(path)
    tiles = get_tile_arrays(image)
    table = make_table(cnn, tiles)
    cSave.archive(table, path)

# CastANet - castanet_predict.py

import os
import numpy as np
import pandas as pd
from keras.preprocessing import image as K_image

import castanet_save as cSave
import castanet_config as cConfig
import castanet_segmentation as cSegm



def normalize(t):
    """ Simple normalization function. """
    return t / 255.0



def make_table(image, model):
    """ Memory-efficient function to predict mycorrhizal structures
        on a large image. Tiles are generated row by row and processed
        on the fly to prevent memory overhead (this would not be a
        problem on HPC. However, one should be able to predict
        mycorrhizal structures on a desktop computer). """

    edge = cConfig.get('tile_edge')
    nrows = image.height // edge
    ncols = image.width // edge

    if nrows == 0 or ncols == 0:

        return None

    else:

        bs = cConfig.get('batch_size')
        c_range = range(ncols)

        # Full row processing, from tile extraction to structure prediction.
        def process_row(r):
            # First, extract all tiles within a row.
            row = [cSegm.tile(image, r, c) for c in c_range]
            # Convert to NumPy array, and normalize.
            row = normalize(np.array(row, np.float32))
            # Predict mycorrhizal structures.
            row = model.predict(row, batch_size=bs)
            # Return prediction as Pandas data frame.
            return pd.DataFrame(row)

        # Retrieve predictions for all rows within the image.
        results = [process_row(r) for r in range(nrows)]

        # Concat to a single Pandas dataframe and add header.
        table = pd.concat(results, ignore_index=True)
        table.columns = cConfig.get('header')

        # Add row and column indexes to the Pandas data frame.
        # col_values = 0, 1, ..., c, 0, ..., c, ..., 0, ..., c; c = ncols - 1
        col_values = list(range(ncols)) * nrows
        # row_values = 0, 0, ..., 0, 1, ..., 1, ..., r, ..., r; r = nrows - 1
        row_values = [x // ncols for x in range(nrows * ncols)]
        table.insert(0, column='col', value=col_values)
        table.insert(0, column='row', value=row_values)

        return table



def run(input_files, model):
  """ For each image given as input, performs segmentation into tiles
      and predicts mycorrhizal structures. The final table is then
      saved as ZIP archive in the same location as the input image. """
  for path in input_files:
    name = os.path.basename(path)
    print('* Predicting mycorrhizal structures on "{}"'.format(name))
    image = K_image.load_img(path)
    table = make_table(image, model)
    cSave.archive(table, path)

# AMFinder - amfinder_predict.py
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
Predicts fungal colonisation (CNN1) and intraradical hyphal structures (CNN2).

Functions
------------

:function normalize: Pixel normalisation function.
:function predict_level2: CNN2 predictions.
:function predict_level1: CNN1 predictions.
:function run: main prediction function.
"""

import io
import os
import pyvips
import numpy as np
import pandas as pd
import zipfile as zf
from itertools import zip_longest

import amfinder_log as AmfLog
import amfinder_save as AmfSave
import amfinder_model as AmfModel
import amfinder_config as AmfConfig
import amfinder_segmentation as AmfSegm

# FIXME: Deactivated due to probable issues with TF 2.1
# import amfinder_activation_mapping as AmfMapping



def normalize(t):
    """
    Simple pixel normalisation function.
    
    :param t: input image (numpy array).
    """

    return t / 255.0



def predict_level2(path, image, nrows, ncols, model):
    """
    Identifies AM fungal structures in colonized root segments.
    
    :param path: path to the input image.
    :param image: input image (to extract tiles).
    :param nrows: row count.
    :param ncols: column count.
    :para model: CNN2 model used for predictions.
    """
    
    #cams = AmfMapping.initialize(nrows, ncols)
    
    zfile = os.path.splitext(path)[0] + '.zip'

    if not zf.is_zipfile(zfile):

        AmfLog.warning(f'The file {path} is not a valid archive')
        return None
   
    with zf.ZipFile(zfile) as z:

        if 'col.tsv' in z.namelist():

            # Retrieve root segmentation data.
            annotations = z.read('col.tsv').decode('utf-8')
            annotations = io.StringIO(annotations)
            annotations = pd.read_csv(annotations, sep='\t')
            
            # Retrieve tiles corresponding to colonized root segments.
            colonized = annotations.loc[annotations["Y"] == 1, ["row", "col"]]
            colonized = [x for x in colonized.values.tolist()]

            # Create tile batches.
            batches = zip_longest(*(iter(colonized),) * 25)
            nbatches = len(colonized) // 25 + int(len(colonized) % 25 != 0)

            def process_batch(batch, b):
                batch = [x for x in batch if x is not None]
                # In prediction mode, AmfSegm.tiles always returns singletons.
                row = [AmfSegm.tile(image, x[0], x[1])[0] for x in batch]
                row = normalize(np.array(row, np.float32))
                # Returns three prediction tables (one per class).
                prd = model.predict(row, batch_size=25)
                # Converts to a table of predictions.
                ap = prd[0].tolist()
                vp = prd[1].tolist()
                hp = prd[2].tolist()       
                ip = prd[3].tolist()
                dat = [[a[0], v[0], h[0], i[0]] for a, v, h, i in 
                       zip(ap, vp, hp, ip)]
                #AmfMapping.generate(cams, model, row, batch)
                res = [[x[0], x[1], y[0], y[1], y[2], y[3]] for (x, y) in
                        zip(batch, dat)]
                AmfLog.progress_bar(b, nbatches, indent=1)
                return pd.DataFrame(res)

            AmfLog.progress_bar(0, nbatches, indent=1)
            results = [process_batch(x, b) for x, b in zip(batches, 
                                                           range(1, nbatches + 1))]
            table = pd.concat(results, ignore_index=True)
            table.columns = ['row', 'col'] + AmfConfig.get('header')

            return (table, None) # None was cams

        else:
        
            # Cannot recover from this error. It means the user is trying
            # to predict intraradical structures (IRStruct) using 
            # unsegmented images (no col annotations).
            zfile_name = os.path.basename(zfile)
            AmfLog.error(f'The archive {zfile_name} does not contain '
                         'stage 1 annotations (fungal colonisation)',
                         AmfLog.ERR_MISSING_ANNOTATIONS)



def predict_level1(image, nrows, ncols, model):
    """
    Identifies colonised root segments. 

    :param image: input image (to extract tiles).
    :param nrows: row count.
    :param ncols: column count. 
    :param model: CNN1 model used for predictions.
    """

    # Creates the images to save the class activation maps.
    #cams = AmfMapping.initialize(nrows, ncols)

    bs = AmfConfig.get('batch_size')
    c_range = range(ncols)

    # Full row processing, from tile extraction to structure prediction.
    def process_row(r):
        # First, extract all tiles within a row.
        row = [AmfSegm.tile(image, r, c)[0] for c in c_range]
        # Convert to NumPy array, and normalize.
        row = normalize(np.array(row, np.float32))
        # Predict mycorrhizal structures.
        prd = model.predict(row, batch_size=bs)
        # Retrieve class activation maps.
        #AmfMapping.generate(cams, model, row, r)
        # Update the progress bar.
        AmfLog.progress_bar(r + 1, nrows, indent=1)
        # Return prediction as Pandas data frame.
        return pd.DataFrame(prd)

    # Initialize the progress bar.
    AmfLog.progress_bar(0, nrows, indent=1)

    # Retrieve predictions for all rows within the image.
    results = [process_row(r) for r in range(nrows)]

    # Concat to a single Pandas dataframe and add header.
    table = pd.concat(results, ignore_index=True)
    table.columns = AmfConfig.get('header')

    # Add row and column indexes to the Pandas data frame.
    # col_values = 0, 1, ..., c, 0, ..., c, ..., 0, ..., c; c = ncols - 1
    col_values = list(range(ncols)) * nrows
    # row_values = 0, 0, ..., 0, 1, ..., 1, ..., r, ..., r; r = nrows - 1
    row_values = [x // ncols for x in range(nrows * ncols)]
    table.insert(0, column='col', value=col_values)
    table.insert(0, column='row', value=row_values)

    return (table, None) # None was cams



def run(input_images, postprocess=None):
    """
    Runs prediction on a bunch of images.
    
    :param input_images: input images to use for predictions.
    :param save: indicate whether results should be saved or returned.
    """

    model = AmfModel.load()
       
    for path in input_images:

        base = os.path.basename(path)
        print(f'* Image {base}')

        edge = AmfConfig.update_tile_edge(path)

        image = pyvips.Image.new_from_file(path, access='random')

        nrows = image.height // edge
        ncols = image.width // edge

        if nrows == 0 or ncols == 0:

            AmfLog.warning('Tile size ({edge} pixels) is too large')
            continue
            
        else:
           
            if AmfConfig.get('level') == 1:
            
                table, cams = predict_level1(image, nrows, ncols, model)

            else:

                table, cams = predict_level2(path, image, nrows, ncols, model)


            # Save results or use continuation for further processing.
            if postprocess is None:

                AmfSave.prediction_table(table, cams, path)
                
            else:
            
                postprocess(table, path)

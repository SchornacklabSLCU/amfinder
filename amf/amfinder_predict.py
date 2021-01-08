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
import amfinder_activation_mapping as AmfMapping



def normalize(t):
    """ Simple normalization function. """

    return t / 255.0



def myc_structures(path, image, nrows, ncols, model):
    """ Identifies AM fungal structures in colonized root segments. """
    
    cams = AmfMapping.initialize(nrows, ncols)
    
    zfile = os.path.splitext(path)[0] + '.zip'

    if not zf.is_zipfile(zfile):

        AmfLog.warning(f'The file {path} is not a valid archive')
        return None

    AmfConfig.import_settings(zfile)
    
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
                row = [AmfSegm.tile(image, x[0], x[1]) for x in batch]
                row = normalize(np.array(row, np.float32))
                # Returns three prediction tables (one per class).
                prd = model.predict(row, batch_size=25)
                # Converts to a table of predictions.
                ap = prd[0].tolist()
                vp = prd[1].tolist()
                hp = prd[2].tolist()       
                ip = prd[3].tolist()
                dat = [[a[0], v[0], h[0], i[0]] for a, v, h, i in zip(ap, vp, hp, ip)]
                #AmfMapping.generate(cams, model, row, r)
                res = [[x[0], x[1], y[0], y[1], y[2], y[3]] for (x, y) in zip(batch, dat)]
                AmfLog.progress_bar(b, nbatches, indent=1)
                return pd.DataFrame(res)

            AmfLog.progress_bar(0, nbatches, indent=1)
            results = [process_batch(x, b) for x, b in zip(batches, 
                                                           range(1, nbatches + 1))]
            table = pd.concat(results, ignore_index=True)
            table.columns = ['row', 'col'] + AmfConfig.get('header')

            return (table, cams)

        else:
        
            # Cannot recover from this error. It means the user is trying
            # to predict intraradical structures (IRStruct) using 
            # unsegmented images (no col annotations).
            image_name = os.path.basename(path)
            zfile_name = os.path.basename(zfile)
            AmfLog.error(f'Image {image_name} has no archive {zfile_name}',
                       AmfLog.ERR_MISSING_ARCHIVE)



def colonization(image, nrows, ncols, model):
    """ Predict mycorrhizal structures row by row. 
        PARAMETERS
        image: pyvips.vimage.Image
            Large image (mosaic) from which tiles are extracted.
        nrows: int
            Tile count on Y axis (image height).
        ncols: int
            Tile count on X axis (image width).
        model: Sequential (tensorflow).
            Model used to predict mycorrhizal structures.
    """

    # Creates the images to save the class activation maps.
    cams = AmfMapping.initialize(nrows, ncols)

    bs = AmfConfig.get('batch_size')
    c_range = range(ncols)

    # Full row processing, from tile extraction to structure prediction.
    def process_row(r):
        # First, extract all tiles within a row.
        row = [AmfSegm.tile(image, r, c) for c in c_range]
        # Convert to NumPy array, and normalize.
        row = normalize(np.array(row, np.float32))
        # Predict mycorrhizal structures.
        prd = model.predict(row, batch_size=bs)
        # Retrieve class activation maps.
        AmfMapping.generate(cams, model, row, r)
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

    return (table, cams)



def run(input_images):
    """ Run prediction on a bunch of images.
        PARAMETER
        input_images: list 
            Images on which to predict mycorrhizal structures.
    """

    model = AmfModel.load()   
    edge = AmfConfig.get('tile_edge')

    for path in input_images:

        base = os.path.basename(path)
        print(f'* Image {base}')

        image = pyvips.Image.new_from_file(path, access='random')

        nrows = image.height // edge
        ncols = image.width // edge

        if nrows == 0 or ncols == 0:

            AmfLog.warning('Tile size ({edge} pixels) is too large')
            continue
            
        else:
           
            if AmfConfig.get('level') == 1:
            
                table, cams = colonization(image, nrows, ncols, model)

            else:

                table, cams = myc_structures(path, image, nrows, ncols, model)

            # Save predictions (<table>) and class activations maps (<cams>)
            # in a ZIP archive derived from the image name (<path>). 
            AmfSave.prediction_table(table, cams, path)

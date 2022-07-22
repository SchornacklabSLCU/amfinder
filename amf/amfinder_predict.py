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

:function predict_level2: CNN2 predictions.
:function predict_level1: CNN1 predictions.
:function run: main prediction function.
"""

import io
import os
import pyvips
import numpy as np
import pandas as pd
import amfinder_zipfile as zf
from itertools import zip_longest
# For intermediate images
from PIL import Image
import matplotlib.pyplot as plt
import tensorflow as tf

import amfinder_log as AmfLog
import amfinder_calc as AmfCalc
import amfinder_save as AmfSave
import amfinder_model as AmfModel
import amfinder_config as AmfConfig
import amfinder_segmentation as AmfSegm
import amfinder_superresolution as AmfSRGAN

# FIXME: Deactivated due to probable issues with TF 2.1
# import amfinder_activation_mapping as AmfMapping



def table_header():

    return ['row', 'col'] + AmfConfig.get('header')



def process_row_1(cnn1, image, nrows, ncols, batch_size, r, sr_image):
    """
    Predict colonisation (CNN1) on a single tile row.
    """
    # First, extract all tiles within a row.
    row = [AmfSegm.tile(image, r, c) for c in range(ncols)]
    # Generate super-resolution tiles.
    row = AmfSRGAN.generate(sr_image, row, r)
    # Convert to NumPy array, and normalize.
    row = AmfSegm.preprocess(row)
    # Predict mycorrhizal structures.
    prd = cnn1.predict(row, batch_size=batch_size, verbose=0)
    # Update the progress bar.
    AmfLog.progress_bar(r + 1, nrows, indent=1)
    # Return prediction as Pandas data frame.
    return pd.DataFrame(prd)


def predict_level2(path, image, nrows, ncols, model):
    """
    Identifies AM fungal structures in colonized root segments.
    
    :param path: path to the input image.
    :param image: input image (to extract tiles).
    :param nrows: row count.
    :param ncols: column count.
    :para model: CNN2 model used for predictions.
    """
   
    zfile = os.path.splitext(path)[0] + '.zip'

    if not zf.is_zipfile(zfile):

        AmfLog.warning(f'Cannot read archive {zfile}.')
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
                # First, extract all tiles from the batch.
                row = [AmfSegm.tile(image, x[0], x[1]) for x in batch]
                row = AmfSegm.preprocess(row)
                # Returns three prediction tables (one per class).
                prd = model.predict(row, batch_size=25, verbose=0)
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
            
            table = None                                       
            if len(results) > 0:
                table = pd.concat(results, ignore_index=True)
                table.columns = table_header()

            return (table, None) # None was cams

        else:
        
            # Cannot recover from this error. It means the user is trying
            # to predict intraradical structures (IRStruct) using 
            # unsegmented images (no col annotations).
            zfile_name = os.path.basename(zfile)
            AmfLog.error(f'The archive {zfile_name} does not contain '
                         'stage 1 annotations (fungal colonisation)',
                         AmfLog.ERR_MISSING_ANNOTATIONS)



def predict_level1(image, nrows, ncols, cnn1):
    """
    Identifies colonised root segments. 

    :param image: input image (to extract tiles).
    :param nrows: row count.
    :param ncols: column count. 
    :param cnn1: trained CNN1 used for predictions.
    """

    # Creates the images to save the class activation maps.
    sr_image = AmfSRGAN.initialize(nrows, ncols)

    # Initialize the progress bar.
    AmfLog.progress_bar(0, nrows, indent=1)

    # Retrieve predictions for all rows within the image.
    bs = AmfConfig.get('batch_size')
    results = [process_row_1(cnn1, image, nrows, ncols, bs, r, sr_image)
               for r in range(nrows)]

    # Concat to a single Pandas dataframe.
    table = pd.concat(results, ignore_index=True)

    # Add row and column indexes to the Pandas data frame.
    # col_values = 0, 1, ..., c, 0, ..., c, ..., 0, ..., c; c = ncols - 1
    # row_values = 0, 0, ..., 0, 1, ..., 1, ..., r, ..., r; r = nrows - 1
    col_values = list(range(ncols)) * nrows
    row_values = [x // ncols for x in range(nrows * ncols)]

    table.insert(0, column='col', value=col_values)
    table.insert(0, column='row', value=row_values)
    table.columns = table_header()

    return (table, sr_image)



def save_conv2d_outputs(model, image, base):
    """
    Save outputs of each Conv2D layer.
    Note: currently only works for a single tile.
    """

    cmap = plt.get_cmap(AmfConfig.get('colormap'))
    submodels = AmfModel.get_feature_extractors(model)

    zipf = '{}_layer_outputs.zip'.format(os.path.splitext(base)[0])
    zipf = os.path.join(AmfConfig.get('outdir'), zipf)

    with zf.ZipFile(zipf, 'w') as z:

        for conv2d, submodel in submodels:

            tiles = [AmfSegm.tile(image, 0, 0)] # TODO: generalise!
            batch = AmfSegm.preprocess(tiles)

            predictions = submodel.predict(batch)

            for i in range(predictions.shape[0]):

                im = predictions[i]

                for channel in range(im.shape[-1]):
                    
                    tmp = cmap(im[:,:, channel])
                    tmp = Image.fromarray(np.uint8(tmp * 255))
                    tmp = tmp.convert('RGB')
                    bytes = io.BytesIO()   
                    tmp.save(bytes, 'JPEG', quality=100) 
                    # Should add i in filename.
                    filename = '{}/channel_{}.jpg'.format(conv2d.name, channel)  
                    z.writestr(filename, bytes.getvalue())



def save_conv2d_kernels(model):
    """
    Save kernels for all convolutional layers.
    """

    cmap = plt.get_cmap(AmfConfig.get('colormap'))
    base = os.path.basename(AmfConfig.get('model'))
    zipf = '{}_kernels.zip'.format(os.path.splitext(base)[0])
    zipf = os.path.join(AmfConfig.get('outdir'), zipf)

    with zf.ZipFile(zipf, 'w') as z:

        iterations = 30
        learning_rate = 10.0

        for (conv2d, submodel) in AmfModel.get_feature_extractors(model):
    
            for filter_index in range(conv2d.output.shape[3]):

                loss, img = AmfCalc.visualize_filter(submodel, filter_index)

                tmp = Image.fromarray(np.uint8(img * 255))
                tmp = tmp.convert('RGB')
                bytes = io.BytesIO()   
                tmp.save(bytes, 'JPEG', quality=100) 
                # Should add i in filename.
                filename = '{}/filter_{}.jpg'.format(conv2d.name, filter_index)  
                z.writestr(filename, bytes.getvalue())



def run(input_images, postprocess=None):
    """
    Runs prediction on a bunch of images.
    
    :param input_images: input images to use for predictions.
    :param save: indicate whether results should be saved or returned.
    """

    model = AmfModel.load()
       
    if AmfConfig.get('save_conv2d_kernels'):
    
        save_conv2d_kernels(model)


    for path in input_images:

        base = os.path.basename(path)
        AmfLog.text(f'Image {base}')

        edge = AmfConfig.update_tile_edge(path)

        image = AmfSegm.load(path)

        nrows = image.height // edge
        ncols = image.width // edge

        if nrows == 0 or ncols == 0:

            AmfLog.warning('Tile size ({edge} pixels) is too large')
            continue
            
        else:
           
            if AmfConfig.get('level') == 1:
            
                table, sr_image = predict_level1(image, nrows, ncols, model)

                if AmfConfig.get('save_conv2d_outputs'):

                    save_conv2d_outputs(model, image, base) 

            else:

                table, sr_image = predict_level2(path, image, nrows, ncols, model)               

            # Save results or use continuation for further processing.
            if postprocess is None:

                # None was cams, reuse for super-resolution.
                AmfSave.prediction_table(table, sr_image, path)
                
            else:
            
                postprocess(image, table, path)

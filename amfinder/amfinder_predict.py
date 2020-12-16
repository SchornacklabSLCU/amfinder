# AMFinder - amfinder_predict.py

import io
import os
import pyvips
import numpy as np
import pandas as pd
import zipfile as zf
from itertools import zip_longest

import amfinder_log as cLog
import amfinder_save as cSave
import amfinder_model as cModel
import amfinder_config as cConfig
import amfinder_segmentation as cSegm
import amfinder_activation_mapping as cMapping



def normalize(t):
    """ Simple normalization function. """

    return t / 255.0



def batch_processing(path, image, nrows, ncols, model):
    
    cams = cMapping.initialize(nrows, ncols)
    
    # Retrieve existing tile size.
    zfile = "{}.zip".format(os.path.splitext(path)[0])
    cConfig.import_settings(zfile)
    root_segm = 'RootSegm.tsv'
    
    with zf.ZipFile(zfile) as z:

        if root_segm in z.namelist():

            annotations = z.read(root_segm).decode('utf-8')
            annotations = io.StringIO(annotations)
            annotations = pd.read_csv(annotations, sep='\t')
            
            # Keep colonized tiles only.
            colonized = annotations.loc[annotations["Y"] == 1, ["row", "col"]]
            # Transform to list of tuples.
            colonized = [x for x in colonized.values.tolist()]
            # Split in batches.
            batches = zip_longest(*(iter(colonized),) * 25)

            def process_batch(batch):
                batch = [x for x in batch if x is not None]
                row = [cSegm.tile(image, x[0], x[1]) for x in batch]
                row = normalize(np.array(row, np.float32))
                prd = model.predict(row, batch_size=25)
                #cMapping.generate(cams, model, row, r)
                #cLog.progress_bar(i + 1, nrows, indent=1)
                res = [[x[0], x[1], y] for (x, y) in zip(batch, prd)]
                return pd.DataFrame(res)

            cLog.progress_bar(0, nrows, indent=1)
            results = [process_batch(x) for x in batches]
            print(results)

            table = pd.concat(results, ignore_index=True)
            print(table)
            table.columns = cConfig.get('header')

            #col_values = list(range(ncols)) * nrows
            #row_values = [x // ncols for x in range(nrows * ncols)]

            #table.insert(0, column='col', value=col_values)
            #table.insert(0, column='row', value=row_values)

            return (table, cams)

        else:
        
            # Cannot recover from this error. It means the user is trying
            # to predict intraradical structures (IRStruct) using 
            # unsegmented images (no RootSegm annotations).
            image_name = os.path.basename(path)
            zfile_name = os.path.basename(zfile)
            cLog.error(f'Image {image_name} has no archive {zipfile_name}',
                       cLog.ERR_MISSING_ARCHIVE)



def row_wise_processing(image, nrows, ncols, model):
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
    cams = cMapping.initialize(nrows, ncols)

    bs = cConfig.get('batch_size')
    c_range = range(ncols)

    # Full row processing, from tile extraction to structure prediction.
    def process_row(r):
        # First, extract all tiles within a row.
        row = [cSegm.tile(image, r, c) for c in c_range]
        # Convert to NumPy array, and normalize.
        row = normalize(np.array(row, np.float32))
        # Predict mycorrhizal structures.
        prd = model.predict(row, batch_size=bs)
        # Retrieve class activation maps.
        cMapping.generate(cams, model, row, r)
        # Update the progress bar.
        cLog.progress_bar(r + 1, nrows, indent=1)
        # Return prediction as Pandas data frame.
        return pd.DataFrame(prd)

    # Initialize the progress bar.
    cLog.progress_bar(0, nrows, indent=1)

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

    return (table, cams)



def run(input_images):
    """ Run prediction on a bunch of images.
        PARAMETER
        input_images: list 
            Images on which to predict mycorrhizal structures.
    """

    model = cModel.load()
    edge = cConfig.get('tile_edge')

    for path in input_images:

        base = os.path.basename(path)
        print(f'* Image {base}')

        image = pyvips.Image.new_from_file(path, access='random')

        nrows = image.height // edge
        ncols = image.width // edge

        if nrows == 0 or ncols == 0:

            cLog.warning('Tile size ({edge} pixels) is too large')
            continue
            
        else:
           
            if cConfig.get('level') == 1:
            
                table, cams = row_wise_processing(image, nrows, ncols, model)

            else:

                table, cams = batch_processing(path, image, nrows, ncols, model)

            # Save predictions (<table>) and class activations maps (<cams>)
            # in a ZIP archive derived from the image name (<path>). 
            cSave.prediction_table(table, cams, path)

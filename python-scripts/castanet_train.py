# CastANet - castanet_train.py

import os
import io
import random
import pickle
import pyvips
import operator
import functools
import numpy as np
import pandas as pd
import zipfile as zf

from keras.callbacks import EarlyStopping
from keras.callbacks import ReduceLROnPlateau
from keras.preprocessing.image import load_img
from keras.preprocessing.image import ImageDataGenerator

from sklearn.model_selection import train_test_split

import castanet_log as cLog
import castanet_plot as cPlot
import castanet_save as cSave
import castanet_model as cModel
import castanet_config as cConfig
import castanet_segmentation as cSegm



def get_data_generator(data_augmentation=False):
    """
    Create an image data generator, including or not data augmentation.
    
    PARAMETER
        - data_augmentation: activates data augmentation.
    
    Returns an image data generator.
    """

    if data_augmentation:
        return ImageDataGenerator(horizontal_flip=True, vertical_flip=True)
    else:

        return ImageDataGenerator()



def load_tile(image, drop, data):
    """
    Load a tile, and drop some background tiles.

    PARAMETERS
        -drop: Percentage of background tiles to drop.
        -image: Source image (mosaic).
        -data: Tile coordinates (row/column) and annotations.
    
    Returns the loaded tile, or None if it was dropped.
    """

    if cConfig.get('level') == 'RootSegm' and drop > 0 and data['X'] == 1 and random.uniform(0, 100) < drop:

        return None

    else:

        return cSegm.tile(image, data['row'], data['col'])



def print_statistics(labels):
    """ Prints statistics irrespective of the annotation level. """

    header = cConfig.get('header')
    hrange = range(len(header))
    counts = list(hrange)

    for hot in labels:

        for i in hrange:

            if hot[i] == 1:

                counts[i] += 1

    print('* Statistics')
    for i in hrange:

        lbl = header[i]
        num = counts[i]
        pct = int(round(100.0 * num / sum(counts)))
        print(f'    - Class {lbl}: {num} tiles ({pct}%)')



def load_annotation_table(level, path):
    """
    Retrieve annotations from a ZIP archive.

    PARAMETERS
        - level: Annotation level.
        - path: Path to the annotated input image.

    RETURNS
        - a Pandas DataFrame containing annotations, or
        - `None` when annotations are not available.
    """

    zip_file = os.path.splitext(path)[0] + '.zip'

    # File exists and is a valid archive.
    if os.path.isfile(zip_file) and zf.is_zipfile(zip_file):

        annot_file = f'{level}.tsv'

        with zf.ZipFile(zip_file, 'r') as z:

            # Check availability of the annotation table at the given level.
            if annot_file in z.namelist():

                annot_table = z.read(annot_file).decode('utf-8')
                annot_table = io.StringIO(annot_table)
                annot_table = pd.read_csv(annot_table, sep='\t')
                
                return annot_table

            else:
              
                return None

    else:
    
        return None



def estimate_drop(counts):
    """
    Determine the percentage of background tiles to be dropped to avoid
    overrepresentation compared to other annotation classes.

    PARAMETERS
        - counts (pandas.Series): Total number of tiles for each annotation
          class, considering all input images.

    RETURNS
        - the percentage of background tiles to drop, or
        - 0 if background tiles are not overrepresented compared to other
          annotation classes.    
    """

    # Number of background tiles.
    background_count = counts['X']

    # Number of tiles with other annotation.
    other_counts = counts.drop(['row', 'col', 'X'])

    # Average tile count per annotation class.
    average = round(sum(other_counts.values) / len(other_counts.index))
    
    # Excess background tiles compared to other classes.
    overhead = background_count - average
    
    if overhead <= 0:
    
        return 0
    
    else:
    
        return round(overhead * 100 / background_count)



def load_annotations(input_files):
    """ Builds the training dataset by extracting tiles from
        large images, removing some background images where
        appropriate. """


    print('* Image segmentation.')

    # Load annotation tables for all input images.
    level = cConfig.get('level')
    annot_tables = [load_annotation_table(level, x) for x in input_files]

    drop = 0

    if cConfig.get('drop') > 0:

        # Remove cases where no pandas.DataFrame was produced
        filtered_tables = [x for x in annot_tables if x is not None]
        
        # Produces counts (pandas.Series) for each input file.
        count_list = [x.sum() for x in filtered_tables]
        
        # Retrieve the grand total.
        counts = functools.reduce(operator.add, count_list)
        
        # Estimate the percentage of background tiles to drop.
        drop = estimate_drop(counts)
        cLog.info(f'{drop}%% of background tiles will be dropped.', indent=1)

    tiles = []
    labels = []
    random.seed(42)
    headers = cConfig.get('header')

    for path, data in zip(input_files, annot_tables):

        base = os.path.basename(path)
        cLog.info(f'- {base}... ', indent=1, end='', flush=True)
       
        if data is None:
            
            print('Failed')
            continue

        image = pyvips.Image.new_from_file(path, access='random')

        # Loads tiles, omitting some background tiles if needed.
        data['tile'] = data.apply(lambda x: load_tile(image, drop, x), axis=1)
        data = data[data['tile'].notnull()]

        # Converts tile annotations to one-hot vectors.
        data['hot'] = data[headers].values.tolist()

        # Fast method to assign the new data to the existing lists.
        # Order does not matter here (data will get shuffled later).
        # Reference: https://stackoverflow.com/a/58898489
        tiles[0:0] = data['tile'].values.tolist()
        labels[0:0] = data['hot'].values.tolist()
        print('OK')

        del image

    print_statistics(labels)

    # Preprocessing and conversion to NumPy arrays.
    preprocess = lambda x: x / 255.0
    labels = np.array(labels, np.uint8)
    tiles = preprocess(np.array(tiles, np.float32))

    return tiles, labels



def get_callbacks():
    """
    Configure Keras callbacks to enable early stopping and learning rate
    reduction on plateau.

    No parameter.

    Returns a list of callback monitors.
    """

    callbacks = []

    cb = EarlyStopping(monitor='val_loss',
           min_delta=0,
           patience=10,
           verbose=1,
           mode='auto',
           restore_best_weights=True)
    cConfig.set('early_stopping', cb)
    callbacks.append(cb)

    cb = ReduceLROnPlateau(monitor='val_loss',
           factor=0.1,
           patience=2,
           verbose=1,
           min_lr=0.0005)
    cConfig.set('reduce_lr_on_plateau', cb)
    callbacks.append(cb)

    return callbacks



def run(input_files):
    """
    Train a model with a set of input images.
    
    PARAMETER
        - input_files: list of input image paths.
    
    No returned value.
    """

    model = cModel.load()

    tiles, labels = load_annotations(input_files)

    # Generates training and validation datasets.
    xt, xc, yt, yc = train_test_split(tiles, labels,
                                      shuffle=True,
                                      test_size=cConfig.get('vfrac') / 100.0,
                                      random_state=42)

    t_gen = get_data_generator(data_augmentation=True)
    v_gen = get_data_generator()

    bs = cConfig.get('batch_size')

    his = model.fit(t_gen.flow(xt, yt, batch_size=bs),
                    steps_per_epoch=len(xt) // bs,
                    epochs=cConfig.get('epochs'),
                    validation_data=v_gen.flow(xc, yc, batch_size=bs),
                    validation_steps=len(xc) // bs,
                    callbacks=get_callbacks(),
                    verbose=1)

    cSave.training_data(his.history, model)

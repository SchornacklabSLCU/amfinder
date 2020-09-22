# CastANet - castanet_train.py

import os
import io
import random
import pickle
import pyvips
import numpy as np
import pandas as pd
import zipfile as zf

from functools import partial
from keras.callbacks import EarlyStopping
from keras.callbacks import ReduceLROnPlateau
from keras.preprocessing.image import load_img
from keras.preprocessing.image import ImageDataGenerator

from sklearn.model_selection import train_test_split

import castanet_plot as cPlot
import castanet_save as cSave
import castanet_model as cModel
import castanet_config as cConfig
import castanet_segmentation as cSegm



def get_data_generator(data_augmentation=False):
    """ Creates a data generator which applies or not data augmentation.
        Data augmentation is kept to a minimum (ie horizontal and vertical
        flip) to avoid signal loss when mycorrhizal structures occur near
        tile edges. """

    if data_augmentation:
        return ImageDataGenerator(horizontal_flip=True, vertical_flip=True)
    else:

        return ImageDataGenerator()



def may_load_tile(level, drop, image, x):
    """ Loads a tile under specific conditions. """

    if x['X'] == 1 and drop > 0 and random.uniform(0, 100) < drop:

        return None

    else:

        return cSegm.tile(image, x['row'], x['col'])



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



def load_annotations(input_files):
    """ Builds the training dataset by extracting tiles from
        large images, removing some background images where
        appropriate. """
    
    level = cConfig.get('level')
    headers = cConfig.get('header')

    # Partial application to avoid using cConfig.get too often.
    tile = partial(may_load_tile, level, cConfig.get('drop'))

    random.seed(42)

    tiles = []
    labels = []

    print('* Image segmentation.')

    for path in input_files:

        base = os.path.basename(path)
        zipf = os.path.splitext(path)[0] + '.zip'

        print(f'    - {base}... ', end='', flush=True)

        if os.path.isfile(zipf) and zf.is_zipfile(zipf):
        
            with zf.ZipFile(zipf, 'r') as z:
                data = z.read(f'python/{level}.tsv').decode('utf-8')
                data = pd.read_csv(io.StringIO(data), sep='\t')

        else: # No annotations or corrupted archive.
        
            print(f'WARNING: Missing annotations for {base}')
            continue

        image = pyvips.Image.new_from_file(path, access='random')

        # Loads tiles (omitting some background tiles if requested).
        data['tile'] = data.apply(lambda x: tile(image, x), axis=1)
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
    """ Initializes Keras callbacks that control learning rate
        and monitor validation loss. """

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
           factor=0.2,
           patience=2,
           verbose=1,
           min_lr=0.001)
    cConfig.set('reduce_lr_on_plateau', cb)
    callbacks.append(cb)

    return callbacks



def run(input_files):
    """ Trains a model (see castanet_model.py) with a set of tiles
        containing mycorrhizal structures. """

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

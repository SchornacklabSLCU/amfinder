# AMFinder - amfinder_train.py
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



""" Training module.
    Trains a convolutional neural network on a set of ink-stained root
    images annotated to highlight fungal colonization (ConvNet I) or
    intraradical fungal structures (ConvNet II). Annotations are stored
    in an auxiliary zip file.
    
    Class
    ------------
    ImageDataGeneratorMO - Custom data generator for multiple single-variable
        outputs. Used with ConvNet II.
        Reference: https://github.com/keras-team/keras/issues/3761
    
    Functions
    ------------
    load_tile - Load a tile (may return None for background tiles).
    print_statistics - Print tile count/percentage for each annotation class.
    read_tsv - Reads the annotation table from the auxiliary zip archive.
    estimate_drop - Estimate background tiles to omit to reduce class imbalance.
    load_dataset - Load training dataset (i.e. tiles and annotations).
    get_callbacks - Set up Keras callbacks.
    run - Run the training session.
"""



import os
import io
import random
import pyvips
import operator
import functools
import zipfile as zf
import numpy as np
import pandas as pd
pd.options.mode.chained_assignment = None

from keras.callbacks import EarlyStopping
from keras.callbacks import ReduceLROnPlateau
from keras.preprocessing.image import ImageDataGenerator
from sklearn.model_selection import train_test_split

import amfinder_log as AmfLog
import amfinder_plot as AmfPlot
import amfinder_save as AmfSave
import amfinder_model as AmfModel
import amfinder_config as AmfConfig
import amfinder_segmentation as AmfSegm



def load_tile(image, drop, data):
    """
    Loads a tile. The function may return None to prevent
    overrepresentation of the background annotation class.
    """

    if AmfConfig.get('level') == 1 and drop > 0 and \
       data['X'] == 1 and random.uniform(0, 100) < drop:

        # Drop the background tile.
        return None

    else:

        return AmfSegm.tile(image, data['row'], data['col'])



def print_statistics(labels):
    """
    Prints the tile count and percentage for each annotation class.
    """

    header = AmfConfig.get('header')
    hrange = range(len(header))
    counts = [0] * len(header)

    for hot in labels:

        for i in hrange:

            if hot[i] == 1:

                counts[i] += 1

    print('* Statistics')

    for i in hrange:
        cls = header[i]
        num = counts[i]
        pct = int(round(100.0 * num / sum(counts)))
        print(f'    - Class {cls}: {num} tiles ({pct}%)')



def read_tsv(level, path):
    """
    Retrieve manual annotations from the ZIP archive associated
    with the input image. Returns a Pandas DataFrame containing
    annotations, `None` in case of error.
    """

    # foo.jpg should come with an auxiliary file foo.zip.
    zfile = os.path.splitext(path)[0] + '.zip'

    if os.path.isfile(zfile) and zf.is_zipfile(zfile):

        # Return the tsv filename to read (either 'col.tsv' or 'myc.tsv').
        tsv = AmConfig.tsv_name()

        with zf.ZipFile(zfile, 'r') as z:

            # Check availability of the annotation table.
            if tsv in z.namelist():

                dat = z.read(tsv).decode('utf-8')
                dat = io.StringIO(dat)
                dat = pd.read_csv(dat, sep='\t')
                
                return (dat, AmfConfig.import_settings(zfile))

            else:
              
                return None

    else:
    
        return None



def estimate_drop(counts):
    """
    Determine the percentage of background tiles to skip to avoid
    overrepresentation of this annotation class. Roots are well
    spaced in most pictures, resulting in large amount of background
    tiles.
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



def load_dataset(input_files):
    """
    Loads the full training dataset by generating tables containing
    tiles and their corresponding annotations.
    """

    print('* Image segmentation.')

    # Load annotation tables for all input images.
    level = AmfConfig.get('level')
    annot_tables = [read_tsv(level, x) for x in input_files]

    drop = 0

    # Skipping background tiles only applies in training level 1. 
    if AmfConfig.get('level') == 1 and AmfConfig.get('drop') > 0:

        # Remove cases where no pandas.DataFrame was produced
        filtered_tables = [x for x in annot_tables if x is not None]
        
        # Produces counts (pandas.Series) for each input file.
        count_list = [x[0].sum() for x in filtered_tables]
        
        # Retrieve the grand total.
        counts = functools.reduce(operator.add, count_list)
        
        # Estimate the percentage of background tiles to drop.
        drop = estimate_drop(counts)
        AmfLog.info(f'{drop}% of background tiles will be dropped', indent=1)

    tiles = []
    labels = []
    random.seed(42)
    headers = AmfConfig.get('header')

    for path, data in zip(input_files, annot_tables):

        if data is None:

            print('Failed')
            continue

        # Updates tile edge for this image.
        tsize = data[1]['tile_edge']
        AmfConfig.set('tile_edge', tsize)
        base = os.path.basename(path)
        print(f'    - {base} (tile size: {tsize} pixels)... ',
              end='', flush=True)

        image = pyvips.Image.new_from_file(path, access='random')

        # Loads tiles, omitting some background tiles if needed.
        data = data[0]
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
    reduction when reaching a plateau.
    """

    # Prevent overfitting and restores best weights.
    e = EarlyStopping(monitor='val_loss',
           min_delta=0,
           patience=8,
           verbose=1,
           mode='auto',
           restore_best_weights=True)
    AmfConfig.set('early_stopping', e)

    # Reduce learning rate for fine tuning.
    r = ReduceLROnPlateau(monitor='val_loss',
           factor=0.2,
           patience=2,
           verbose=1,
           min_lr=0.000001)
    AmfConfig.set('reduce_lr_on_plateau', r)

    return [e, r]



class ImageDataGeneratorMO(ImageDataGenerator):
    """
    Patched version of Keras's ImageDataGenerator to support multiple
    single-variable outputs. This requires output data to be a list of 
    identical-length 1D NumPy arrays. Any inefficiency is negligible.
    Reference: https://github.com/keras-team/keras/issues/3761
    """

    def flow(self, x, y=None, **kwargs):
        if y is None or \
        not isinstance(y,list) or \
        any([yy.ndim != 1 for yy in y]) or \
        any([yy.size != len(x) for yy in y]):
           raise ValueError('ImageDataGeneratorMO requires a '
                            'list of outputs, each a 1D NumPy array of the '
                             'same length as the input.')

        y_sing = np.transpose(np.asarray(y))

        generator_sing = super(ImageDataGeneratorMO, 
                               self).flow(x, y_sing, **kwargs)

        while True:
            batch_x, batch_y_sing = next(generator_sing)
            batch_y = [yy for yy in np.transpose(batch_y_sing)]
            yield batch_x, batch_y



def run(input_files):
    """
    Creates or loads a convolutional neural network, and trains it
    with the annotated tiles extracted from input images.
    """

    # Input model (either new or pre-trained).
    model = AmfModel.load()

    # Input tiles and their corresponding annotations.
    tiles, labels = load_dataset(input_files)

    # Generates training and validation datasets.
    xt, xc, yt, yc = train_test_split(tiles, labels,
                                      shuffle=True,
                                      test_size=AmfConfig.get('vfrac') / 100.0,
                                      random_state=42)

    t_gen = None
    v_gen = None

    if AmfConfig.get('level') == 1:

        # Root segmentation (colonized vs non-colonized vs background).
        # ConvNet I has a standard, single input/single output architecture,
        # and can use ImageDataGenerator.
        t_gen = ImageDataGenerator(horizontal_flip=True, vertical_flip=True)
        v_gen = ImageDataGenerator()

    else:

        # AM fungal structures (arbuscules, vesicles, hyphae).
        # ConvNet II has multiple outputs. ImageDataGenerator is not suitable.
        # Reference: https://github.com/keras-team/keras/issues/3761
        t_gen = ImageDataGeneratorMO(horizontal_flip=True, vertical_flip=True)
        v_gen = ImageDataGeneratorMO()
        # Reshape one-hot data in a way suitable for ImageDataGeneratorMO:
        # [[a1 v1 h1]...[aN vN hN]] -> [[a1...aN] [v1...vN] [h1...hN]]
        nclasses = len(AmfConfig.get('header')) # (= 4)
        yt = [np.array([x[i] for x in yt]) for i in range(nclasses)]
        yc = [np.array([x[i] for x in yc]) for i in range(nclasses)]

    bs = AmfConfig.get('batch_size')

    his = model.fit(t_gen.flow(xt, yt, batch_size=bs),
                    steps_per_epoch=len(xt) // bs,
                    epochs=AmfConfig.get('epochs'),
                    validation_data=v_gen.flow(xc, yc, batch_size=bs),
                    validation_steps=len(xc) // bs,
                    callbacks=get_callbacks(),
                    verbose=1)

    AmfSave.training_data(his.history, model)

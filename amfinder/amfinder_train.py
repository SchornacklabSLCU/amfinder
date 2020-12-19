# AMFinder - amfinder_train.py

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
    Load a tile, and drop some background tiles.

    PARAMETERS
        -drop: Percentage of background tiles to drop.
        -image: Source image (mosaic).
        -data: Tile coordinates (row/column) and annotations.
    
    Returns the loaded tile, or None if it was dropped.
    """

    if AmfConfig.get('level') == 1 and drop > 0 and \
       data['X'] == 1 and random.uniform(0, 100) < drop:

        return None

    else:

        return AmfSegm.tile(image, data['row'], data['col'])



def print_statistics(labels):
    """ Prints statistics irrespective of the annotation level. """

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

    zfile = os.path.splitext(path)[0] + '.zip'

    if os.path.isfile(zfile) and zf.is_zipfile(zfile):

        annot_file = 'RootSegm.tsv' if level == 1 else 'IRStruct.tsv'

        with zf.ZipFile(zfile, 'r') as z:

            # Check availability of the annotation table at the given level.
            if annot_file in z.namelist():

                t = z.read(annot_file).decode('utf-8')
                t = io.StringIO(t)
                t = pd.read_csv(t, sep='\t')
                
                return (t, AmfConfig.import_settings(zfile))

            else:
              
                return None

    else:
    
        return None



def estimate_drop(counts):
    """
    Determine the percentage of background tiles to be dropped to avoid
    their overrepresentation compared to other annotation classes.

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
    level = AmfConfig.get('level')
    annot_tables = [load_annotation_table(level, x) for x in input_files]

    drop = 0

    # Drop estimation is only active when training root segmentation. 
    if AmfConfig.get('level') == 'RootSegm' and AmfConfig.get('drop') > 0:

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

        # Updates tile edge for this image.
        tsize = data[1]['tile_edge']
        AmfConfig.set('tile_edge', tsize)
        base = os.path.basename(path)
        print(f'    - {base} (tile size: {tsize})... ', end='', flush=True)
       
        if data is None:

            print('Failed')
            continue

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
    AmfConfig.set('early_stopping', cb)
    callbacks.append(cb)

    cb = ReduceLROnPlateau(monitor='val_loss',
           factor=0.1,
           patience=2,
           verbose=1,
           min_lr=0.0005)
    AmfConfig.set('reduce_lr_on_plateau', cb)
    callbacks.append(cb)

    return callbacks



class ImageDataGeneratorMO(ImageDataGenerator):
    """
    Patched version of Keras's ImageDataGenerator to support multiple
    single-variable outputs. This requires output data to be a list of 
    identical-length 1D NumPy arrays. Any inefficiency is negligible.
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
    Train a model with a set of input images.
    
    PARAMETER
        - input_files: list of input image paths.
    
    No returned value.
    """

    model = AmfModel.load()
    #print(model.summary())

    tiles, labels = load_annotations(input_files)

    # Generates training and validation datasets.
    xt, xc, yt, yc = train_test_split(tiles, labels,
                                      shuffle=True,
                                      test_size=AmfConfig.get('vfrac') / 100.0,
                                      random_state=42)

    t_gen = None
    v_gen = None

    if AmfConfig.get('level') == 1:

        # Root segmentation (colonized vs non-colonized vs background).
        # ConvNet I has a standard single input/single output architecture.
        t_gen = ImageDataGenerator(horizontal_flip=True, vertical_flip=True)
        v_gen = ImageDataGenerator()

    else:

        # AM fungal structures (arbuscules, vesicles, hyphae).
        # ConvII has multiple outputs and ImageDataGenerator is not suitable.
        # Reference: https://github.com/keras-team/keras/issues/3761
        t_gen = ImageDataGeneratorMO(horizontal_flip=True, vertical_flip=True)
        v_gen = ImageDataGeneratorMO()
        # Reshape one-hot data in a way suitable for ImageDataGeneratorMO:
        # [[a1 v1 h1]...[aN vN hN]] -> [[a1...aN] [v1...vN] [h1...hN]]
        yt = [np.array([x[i] for x in yt]) for i in range(3)]
        yc = [np.array([x[i] for x in yc]) for i in range(3)]

    bs = AmfConfig.get('batch_size')

    his = model.fit(t_gen.flow(xt, yt, batch_size=bs),
                    steps_per_epoch=len(xt) // bs,
                    epochs=AmfConfig.get('epochs'),
                    validation_data=v_gen.flow(xc, yc, batch_size=bs),
                    validation_steps=len(xc) // bs,
                    callbacks=get_callbacks(),
                    verbose=1)

    AmfSave.training_data(his.history, model)

# AMFinder - amfinder_config.py
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
AMFinder configuration module.
Read command-line arguments and store user settings.

Variables
------------
HEADERS - Table headers for the different annotation levels. 
PAR - User settings.

Functions
------------
tsv_name - Return the TSV file corresponding to the current annotation level.
get - Retrieve the value associated with the given parameter ID.
colonization - Indicate whether the current level is level 1 (colonization).
intra_struct - Indicate whether the current level is level 2 (structures).
set - Assign a new value to the given parameter ID.
training_subparser - Define the command-line parser used in training mode.
prediction_subparser - Define the command-line parser used in prediction mode.
build_arg_parser - Build the full command-line parser.
import_settings - Read tile size from `settings.json`.
get_input_files - Return the list of vaid input images (based on MIME type).
initialize - Read command-line arguments and store user-defined values.
"""


import os
import cv2
import glob
import yaml
import mimetypes
import zipfile as zf
from argparse import ArgumentParser
from argparse import RawTextHelpFormatter

import amfinder_log as AmfLog



HEADERS = [['Y', 'N', 'X'], ['A', 'V', 'H', 'I']]

PAR = {
    'run_mode': None,
    'level': 1,
    'model': None,
    'tile_edge': 126,
    'input_files': ['*.jpg'],
    'batch_size': 64,
    'learning_rate': 0.001,
    'drop': True,
    'epochs': 100,
    'vfrac': 15,
    'header': HEADERS[0],
    'generate_cams': False,
    'colormap': cv2.COLORMAP_JET,
    'monitors': {
        'csv_logger': None,
        'early_stopping': None,
        'reduce_lr_on_plateau': None,
        'model_checkpoint': None,
    }
}



def tsv_name():
    """
    Return the TSV file corresponding to the current annotation level. 
    """

    if PAR['level'] == 1:
    
        return 'col.tsv'
    
    else:

        return 'myc.tsv'



def get(id):
    """
    Retrieve application settings.
    """

    id = id.lower()

    if id in PAR:
    
        return PAR[id]
    
    elif id in PAR['monitors']:
    
        return PAR['monitors'][id]

    else:

        AmfLog.warning(f'Unknown parameter {id}')
        return None



def colonization():
    """
    Indicate whether the current level is level 1 (colonization).
    """

    return get('level') == 1



def intra_struct():
    """
    Indicate whether the current level is level 2 (AM fungal structures).
    """

    return get('level') == 2



def set(id, value, create=False):
    """
    Updates application settings.
    """

    if value is None:
    
        return

    else:
    
        id = id.lower()

        if id in PAR:
        
            PAR[id] = value

            if id == 'level':
            
                PAR['header'] = HEADERS[int(value == 2)] # Ensures 0 or 1.

        elif id in PAR['monitors']:

            PAR['monitors'][id] = value

        elif create:

            PAR[id] = value

        else:

            AmfLog.warning(f'Unknown parameter {id}')



def training_subparser(subparsers):
    """
    Defines arguments used in training mode.
    """

    parser = subparsers.add_parser('train',
        help='learns how to identify AMF structures.',
        formatter_class=RawTextHelpFormatter)

    x = PAR['tile_edge']
    parser.add_argument('-t', '--tile_size',
        action='store', dest='edge', type=int, default=x,
        help='tile edge (in pixels) used for image segmentation.'
             '\ndefault value: {} pixels'.format(x))

    x = PAR['batch_size']
    parser.add_argument('-bs', '--batch_size',
        action='store', dest='batch_size', metavar='NUM', type=int, default=x,
        help='training batch size.'
             '\ndefault value: {}'.format(x))

    x = PAR['drop']
    parser.add_argument('-k', '--keep_background',
        action='store_false', dest='drop', default=x,
        help='do not drop any background tile.'
             '\nby default, skips excess background tiles.')

    x = PAR['epochs']
    parser.add_argument('-e', '--epochs',
        action='store', dest='epochs', metavar='NUM', type=int, default=x,
        help='number of epochs to run.'
             '\ndefault value: {}'.format(x))

    x = PAR['learning_rate']
    parser.add_argument('-lr', '--learning_rate',
        action='store', dest='learning_rate', metavar='NUM',
        type=int, default=x,
        help='learning rate used with adam optimizer.'
             '\ndefault value: {}'.format(x))

    x = PAR['vfrac']
    parser.add_argument('-vf', '--validation_fraction',
        action='store', dest='vfrac', metavar='N%', type=int, default=x,
        help='Percentage of tiles used for validation.'
             '\ndefault value: {}%%'.format(x))

    parser.add_argument('-myc', '--hyphal_structures',
        action='store_const', dest='level', const=2,
        help='Train for fungal hyphal structures (arbuscule, vesicle, hypha).'
             '\nBy default, train for fungal root colonization.')

    x = None
    parser.add_argument('-net', '--trained_network',
        action='store', dest='model', metavar='H5', type=str, default=x,
        help='path to the pre-trained model.'
             '\ndefault value: {}'.format(x))

    x = PAR['input_files']
    parser.add_argument('image', nargs='*',
        default=x,
        help='plant root scan to be processed.'
             '\ndefault value: {}'.format(x))

    return parser



def prediction_subparser(subparsers):
    """
    Defines arguments used in prediction mode.
    """

    parser = subparsers.add_parser('predict',
        help='Runs AMFinder in prediction mode.',
        formatter_class=RawTextHelpFormatter)

    x = PAR['tile_edge']
    parser.add_argument('-t', '--tile_size',
        action='store', dest='edge', type=int, default=x,
        help='Tile size (in pixels) used for image segmentation.'
             '\ndefault value: {} pixels'.format(x))

    x = PAR['generate_cams']
    parser.add_argument('-cam', '--class_activation_maps',
        action='store_true', dest='generate_cams', default=x,
        help='Generate class activation map (takes some time).'
             '\ndefault value: {}'.format(x))

    x = PAR['colormap']
    parser.add_argument('-c', '--opencv_colormap',
        action='store', dest='colormap', metavar='N', type=int, default=x,
        help='OpenCV colormap (see OpenCV documentation).'
             '\ndefault value: {}'.format(x))

    x = 'pre-trained/RootSegm.h5'
    parser.add_argument('-net', '--trained_network',
        action='store', dest='model', metavar='H5', type=str, default=x,
        help='path to the pre-trained model.'
             '\ndefault value: {}'.format(x))

    x = PAR['input_files']
    parser.add_argument('image', nargs='*', default=x,
        help='plant root scan to be processed.'
             '\ndefault value: {}'.format(x))

    return parser



def build_arg_parser():
    """
    Builds AMFinder command-line parser.
    """

    main = ArgumentParser(description='AMFinder command-line arguments.',
                          allow_abbrev=False,
                          formatter_class=RawTextHelpFormatter)

    subparsers = main.add_subparsers(dest='run_mode', required=True,
                                     help='action to be performed.')

    _ = training_subparser(subparsers)
    _ = prediction_subparser(subparsers)

    return main



def abspath(files):
    """
    Expand wildcards and return absolute paths to input files.
    """

    files = sum([glob.glob(x) for x in files], [])
    return [os.path.abspath(x) for x in files]



def import_settings(zfile):
    """
    Import settings.
    """

    with zf.ZipFile(zfile) as z:

        jfile = 'settings.json'

        if jfile in z.namelist():
        
            x = z.read(jfile).decode('utf-8')
            x = yaml.safe_load(x)
            return x

        else:
        
            return {'tile_size': get('tile_edge')}



def get_input_files():
    """
    Filter input file list and keep valid JPEG or TIFF images.
    """

    raw_list = abspath(get('input_files'))
    valid_types = ['image/jpeg', 'image/tiff']
    images = [x for x in raw_list if mimetypes.guess_type(x)[0] in valid_types]
    print('* Input images: {}'.format(len(images)))
    return images



def initialize():
    """
    Read command line and store user settings.
    """

    parser = build_arg_parser()
    par = parser.parse_known_args()[0]

    # Main arguments.
    set('run_mode', par.run_mode)
    set('tile_edge', par.edge)
    set('input_files', par.image)

    # Sub-parser specific arguments.
    if par.run_mode == 'train':

        set('batch_size', par.batch_size)
        set('drop', par.drop)
        set('epochs', par.epochs)
        set('model', par.model)
        set('level', par.level)
        set('vfrac', par.vfrac)
    
    else: # par.run_mode == 'predict'

        set('model', par.model)
        set('generate_cams', par.generate_cams)
        set('colormap', par.colormap)

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
:HEADERS: Table headers for the different annotation levels. 
:PAR: User settings.

Functions
------------
:function string_of_level: Returns the CNN name for the given prediction level.
:function tsv_name: Return the TSV file corresponding to the current annotation level.
:function human_redable_header: Human-readable annotation class labels.
:function get: Retrieve the value associated with the given parameter ID.
:function colonization: Indicate whether the current level is level 1 (colonization).
:function intra_struct: Indicate whether the current level is level 2 (structures).
:function set: Assign a new value to the given parameter ID.
:function training_subparser: Define the command-line parser used in training mode.
:function prediction_subparser: Define the command-line parser used in prediction mode.
:function build_arg_parser: Build the full command-line parser.
:function import_settings: Read tile size from `settings.json`.
:function get_input_files: Return the list of vaid input images (based on MIME type).
:function initialize: Read command-line arguments and store user-defined values.
"""


import os
import glob
import yaml
import datetime
import mimetypes
import amfinder_zipfile as zf
from argparse import ArgumentParser
from argparse import RawTextHelpFormatter

import amfinder_log as AmfLog



HEADERS = [['Y', 'N', 'X'], ['A', 'V', 'H', 'I']]
HUMAN_HEADERS = [['M+', 'M−', 'Other'], ['Arb', 'Ves', 'Hyp', 'IH']]
DESCRIPTIONS = [['colonized', 'non-colonised', 'background'], 
                ['arbuscules', 'vesicles', 'hyphopodia', 'intraradical hyphae']]

PAR = {
    'run_mode': None,
    'level': 1,
    'model': None,
    'tile_edge': 126,
    'input_files': ['*.jpg'],
    'batch_size': 32,
    'learning_rate': 0.001,
    'drop': True,
    'epochs': 100,
    'vfrac': 15,
    'threshold': 0.5,
    'data_augm': False,
    'save_augmented_tiles': 0,
    'summary': False,
    'patience': 12,
    'outdir': os.getcwd(),
    'header': HEADERS[0],
    'generator': None,
    'discriminator': None,
    'super_resolution': False,
    'save_conv2d_kernels': False,
    'save_conv2d_outputs': False, 
    'colormap': 'plasma',
    'monitors': {
        'csv_logger': None,
        'early_stopping': None,
        'reduce_lr_on_plateau': None,
        'model_checkpoint': None,
    }
}


APP_PATH = os.path.dirname(os.path.realpath(__file__))


def get_appdir():
    """ Returns the application directory. """

    return APP_PATH



def invite():
    """
    Command-line invite
    """
    return datetime.datetime.now().strftime('%H:%M:%S')


def get_class_documentation():
    """
    Return class documentation.
    """
    data = [[f'{x} ({y})' for x, y in zip(b, a)]
            for b, a in zip (HUMAN_HEADERS, DESCRIPTIONS)]

    return ', '.join(data[PAR['level'] - 1])


def string_of_level():
    """
    Return the name corresponding to the current annotation level. 
    """

    return 'col' if PAR['level'] == 1 else 'myc'



def tsv_name():
    """
    Return the TSV file corresponding to the current annotation level. 
    """

    return string_of_level() + '.tsv'



def human_redable_header():
    """
    Return the human-readable header of the current annotation level.
    """

    return HUMAN_HEADERS[PAR['level'] - 1]



def get(id):
    """
    Retrieve application settings.
    
    :param id: Unique identifier.
    """

    id = id.lower()

    if id in PAR:
    
        # Special case, look into a specific folder.
        if id in ['generator', 'discriminator', 'model'] and \
           PAR[id] is not None:
        
            return os.path.join(get_appdir(),
                                'trained_networks',
                                os.path.basename(PAR[id]))

        else:
    
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
    
    :param id: unique identifier.
    :param value: value to store.
    :param create: create id if it does not exist (optional).
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
    
    :param subparsers: subparser generator.
    """

    parser = subparsers.add_parser('train',
        help='learns how to identify AMF structures.',
        formatter_class=RawTextHelpFormatter)

    x = PAR['batch_size']
    parser.add_argument('-b', '--batch_size',
        action='store', dest='batch_size', metavar='NUM', type=int, default=x,
        help='training batch size.'
             '\ndefault value: {}'.format(x))

    x = PAR['drop']
    parser.add_argument('-k', '--keep_background',
        action='store_false', dest='drop', default=x,
        help='keep all background tiles.'
             '\nby default, downscale background to equilibrate classes.')

    x = PAR['data_augm']
    parser.add_argument('-a', '--data_augmentation',
        action='store_true', dest='data_augm', default=x,
        help='apply data augmentation (hue, chroma, saturation, etc.)'
             '\nby default, data augmentation is not used.')

    x = PAR['save_augmented_tiles']
    parser.add_argument('-sa', '--save_augmented_tiles',
        action='store', dest='save_augmented_tiles',
        metavar='NUM', type=int, default=x,
        help='save a subset of augmented tiles.'
             '\nby default, does not save any tile.')

    x = PAR['summary']
    parser.add_argument('-s', '--summary',
        action='store_true', dest='summary', default=x,
        help='save CNN architecture (CNN graph and model summary)'
             '\nby default, does not save any information.')

    x = PAR['outdir']
    parser.add_argument('-o', '--outdir',
        action='store', dest='outdir', default=x,
        help='folder where to save trained model and CNN architecture.'
             '\ndefault: {}'.format(x))

    x = PAR['epochs']
    parser.add_argument('-e', '--epochs',
        action='store', dest='epochs', metavar='NUM', type=int, default=x,
        help='number of epochs to run.'
             '\ndefault value: {}'.format(x))

    x = PAR['patience']
    parser.add_argument('-p', '--patience',
        action='store', dest='patience', metavar='NUM', type=int, default=x,
        help='number of epochs to wait before early stopping is triggered.'
             '\ndefault value: {}'.format(x))

    x = PAR['learning_rate']
    parser.add_argument('-lr', '--learning_rate',
        action='store', dest='learning_rate', metavar='NUM',
        type=int, default=x,
        help='learning rate used by the Adam optimizer.'
             '\ndefault value: {}'.format(x))

    x = PAR['vfrac']
    parser.add_argument('-vf', '--validation_fraction',
        action='store', dest='vfrac', metavar='N%', type=int, default=x,
        help='Percentage of tiles used for validation.'
             '\ndefault value: {}%%'.format(x))

    level = parser.add_mutually_exclusive_group()

    level.add_argument('-1', '--CNN1',
        action='store_const', dest='level', const=1,
        help='Train for root colonisation (default)')

    level.add_argument('-2', '--CNN2',
        action='store_const', dest='level', const=2,
        help='Train for fungal hyphal structures.')

    x = None
    parser.add_argument('-net', '--network',
        action='store', dest='model', metavar='H5', type=str, default=x,
        help='name of the pre-trained network to use as a basis for training.'
             '\ndefault value: {}'.format(x))

    parser.add_argument('-sr', '--super_resolution',
        action='store_const', dest='super_resolution', const=True,
        help='Apply super-resolution before predictions.'
             '\ndefault value: no super-resolution.')

    x = None
    parser.add_argument('-g', '--generator',
        action='store', dest='generator', metavar='H5', type=str, default=x,
        help='name of the pre-trained generator.'
             '\ndefault value: {}'.format(x))

    x = None
    parser.add_argument('-d', '--discriminator',
        action='store', dest='discriminator', metavar='H5', type=str, default=x,
        help='name of the pre-trained discriminator.'
             '\ndefault value: {}'.format(x))

    x = PAR['input_files']
    parser.add_argument('image', nargs='*',
        default=x,
        help='plant root image to process.'
             '\ndefault value: {}'.format(x))

    return parser



def prediction_subparser(subparsers):
    """
    Defines arguments used in prediction mode.
    
    :param subparsers: subparser generator.
    """

    parser = subparsers.add_parser('predict',
        help='Runs AMFinder in prediction mode.',
        formatter_class=RawTextHelpFormatter)

    x = PAR['tile_edge']
    parser.add_argument('-t', '--tile_size',
        action='store', dest='edge', type=int, default=x,
        help='Tile size (in pixels) used for image segmentation.'
             '\ndefault value: {} pixels'.format(x))

    parser.add_argument('-sr', '--super_resolution',
        action='store_const', dest='super_resolution', const=True,
        help='Apply super-resolution before predictions.'
             '\ndefault value: no super-resolution.')

    x = 'SRGANGenv1beta.h5'
    parser.add_argument('-g', '--generator',
        action='store', dest='generator', metavar='H5', type=str, default=x,
        help='name of the pre-trained generator.'
             '\ndefault value: {}'.format(x))

    x = PAR['colormap']
    parser.add_argument('-map', '--colormap',
        action='store', dest='colormap', metavar='id', type=str, default=x,
        help='Name of the colormap used to display conv2d outputs and kernels.'
             '\ndefault value: {}'.format(x))

    x = 'CNN1v2.h5'
    parser.add_argument('-net', '--network',
        action='store', dest='model', metavar='H5', type=str, default=x,
        help='name of the pre-trained model to use for predictions.'
             '\ndefault value: {}'.format(x))

    parser.add_argument('-so', '--save_conv2d_outputs',
        action='store_const', dest='save_conv2d_outputs', const=True,
        help='save conv2d outputs in a separate zip file.'
             '\ndefault value: False')

    parser.add_argument('-sk', '--save_conv2d_kernels',
        action='store_const', dest='save_conv2d_kernels', const=True,
        help='save convolution kernels in a separate zip file (takes time).'
             '\ndefault value: False')

    x = PAR['input_files']
    parser.add_argument('image', nargs='*', default=x,
        help='plant root scan to be processed.'
             '\ndefault value: {}'.format(x))

    return parser



def diagnostic_subparser(subparsers):
    """
    Defines arguments used in diagnostic mode.
    
    :param subparsers: subparser generator.
    """

    parser = subparsers.add_parser('diagnose',
        help='Runs AMFinder in diagnostic mode.',
        formatter_class=RawTextHelpFormatter)

    x = 'CNN1_pretrained_2021-01-18.h5'
    parser.add_argument('-net', '--network',
        action='store', dest='model', metavar='H5', type=str, default=x,
        help='name of the pre-trained model to use for diagnostic.'
             '\ndefault value: {}'.format(x))

    x = PAR['input_files']
    parser.add_argument('image', nargs='*', default=x,
        help='plant root scan to be processed.'
             '\ndefault value: {}'.format(x))

    return parser



def conversion_subparser(subparsers):

    parser = subparsers.add_parser('convert',
        help='Runs AMFinder in conversion mode.',
        formatter_class=RawTextHelpFormatter)

    x = PAR['threshold']
    parser.add_argument('-th', '--threshold',
        action='store', dest='threshold', metavar='N', type=float, default=x,
        help='threshold for conversion: {}'.format(x))

    level = parser.add_mutually_exclusive_group()

    level.add_argument('-1', '--CNN1',
        action='store_const', dest='level', const=1,
        help='Convert root colonisation predictions (default)')

    level.add_argument('-2', '--CNN2',
        action='store_const', dest='level', const=2,
        help='Convert fungal hyphal structure predictions.')

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
    _ = diagnostic_subparser(subparsers)
    _ = conversion_subparser(subparsers)

    return main



def abspath(files):
    """
    Returns absolute paths to input files.
    
    :param files: Raw list of input file names (can contain wildcards).
    """

    files = sum([glob.glob(x) for x in files], [])
    return [os.path.abspath(x) for x in files]



def update_tile_edge(path):
    """
    Import image settings (currently tile edge).
    
    :param path: path to the input image.
    """

    zfile = os.path.splitext(path)[0] + '.zip'

    if zf.is_zipfile(zfile):

        with zf.ZipFile(zfile) as z:

            if 'settings.json' in z.namelist():
            
                x = z.read('settings.json').decode('utf-8')
                x = yaml.safe_load(x)
                set('tile_edge', x['tile_edge'])

    return get('tile_edge')



def get_input_files():
    """
    Filter input file list and keep valid JPEG or TIFF images.
    """

    raw_list = abspath(get('input_files'))
    valid_types = ['image/jpeg', 'image/tiff']
    images = [x for x in raw_list if mimetypes.guess_type(x)[0] in valid_types]
    AmfLog.text(f'Input images: {len(images)}')
    return images



def initialize():
    """
    Read command line and store user settings.
    """

    parser = build_arg_parser()
    par = parser.parse_known_args()[0]

    # Main arguments.
    set('run_mode', par.run_mode)
    set('input_files', par.image)

    # Sub-parser specific arguments.
    if par.run_mode == 'train':

        set('batch_size', par.batch_size)
        set('drop', par.drop)
        set('epochs', par.epochs)
        set('model', par.model)
        set('level', par.level)
        set('vfrac', par.vfrac)
        set('data_augm', par.data_augm)
        set('summary', par.summary)
        set('outdir', par.outdir)
        # Parameters associated with super-resolution. 
        set('super_resolution', par.super_resolution)
        set('generator', par.generator)
        set('discriminator', par.discriminator)

    elif par.run_mode == 'predict':

        set('tile_edge', par.edge)
        set('model', par.model)
        set('save_conv2d_kernels', par.save_conv2d_kernels)   
        set('save_conv2d_outputs', par.save_conv2d_outputs)   
        set('colormap', par.colormap)
        # Parameters associated with super-resolution. 
        set('super_resolution', par.super_resolution)
        set('generator', par.generator)

    elif par.run_mode == 'diagnose': 
        
        set('model', par.model)   
    
    elif par.run_mode == 'convert':
   
        set('level', par.level)
        set('threshold', par.threshold)
        
    else:
    
        pass

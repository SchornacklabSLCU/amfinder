# CastANet - amfinder_config.py

import os
import cv2
import glob
import mimetypes
from argparse import ArgumentParser
from argparse import RawTextHelpFormatter

import amfinder_log as cLog

HEADERS = {
  'RootSegm': ['Y', 'N', 'X'],
  'IRStruct': ['A', 'V', 'H']
}

PAR = {
    'run_mode': None,
    'level': None,
    'model': None,
    'tile_edge': None,
    'model_input_size': 126,
    'input_files': None,
    'batch_size': None,
    'drop': None,
    'epochs': None,
    'vfrac': None,
    'header': HEADERS['RootSegm'],
    'outdir': None,
    'generate_cams': None,
    'colormap': None,
    'monitors': {
        'csv_logger': None,
        'early_stopping': None,
        'reduce_lr_on_plateau': None,
        'model_checkpoint': None,
    }
}



def get(id):
    """
    Retrieve application settings by name.
    PARAMETER
        id      The identifier of the application setting to retrieve.
    """

    id = id.lower()

    if id in PAR: return PAR[id]
    if id in PAR['monitors']: return PAR['monitors'][id]

    cLog.warning(f'Unknown parameter {id}')
    return None



def set(id, value, create=False):
    """
    Update application settings.
    PARAMETERS
        id      The identifier of the application setting to update.
        value   The value to be stored. 
        create  Create a new pair should the identifier not exist.
    """

    if value is None: return

    id = id.lower()

    if id in PAR:
    
        PAR[id] = value
        # Automatically adjust header to annotation level.
        if id == 'level': PAR['header'] = HEADERS[value]

    elif id in PAR['monitors']:

        PAR['monitors'][id] = value

    elif create:

        PAR[id] = value

    else:

        cLog.warning(f'Unknown parameter {id}')



def build_argumentp():
  """ This function builds CastAnet command-line parser. The parser
      consists of two mutually exclusive sub-parsers: <train> and
      <predict>. The former defines arguments concerning the learning
      step, while the latter defines those associated with the
      prediction of mycorrhizal structures. Each sub-parser comes with
      a specific set of optional arguments. Beside sub-parsers, the
      main parser also defines general arguments such as tile size
      and annotation level. """
  main = ArgumentParser(description='CastANet command-line arguments.',
                        allow_abbrev=False,
                        formatter_class=RawTextHelpFormatter)

  subparsers = main.add_subparsers(dest='run_mode', required=True,
                                   help='action to be performed.')

  # Subparser dedicated to network training using pre-annotated images.
  tp = subparsers.add_parser('train',
                             help='learns how to identify AMF structures.',
                             formatter_class=RawTextHelpFormatter)

  tp.add_argument('-t', '--tile',
                  action='store', dest='edge',
                  type=int, default=40,
                  help='tile edge (in pixels) used for image segmentation.'
                       '\ndefault value: 40 pixels')

  tp.add_argument('-b', '--batch',
                  action='store', dest='batch_size', metavar='NUM',
                  type=int, default=32,
                  help='training batch size.'
                       '\ndefault value: 32')

  tp.add_argument('-k', '--keep',
                  action='store_false', dest='drop', default=True,
                  help='do not drop any background tile.'
                       '\nby default, drops background tiles in excess.')

  tp.add_argument('-e', '--epochs',
                  action='store', dest='epochs', metavar='NUM',
                  type=int, default=100,
                  help='number of epochs to run.'
                       '\ndefault value: 100')

  tp.add_argument('-f', '--fraction',
                  action='store', dest='vfrac', metavar='N%',
                  type=int, default=15,
                  help='Percentage of tiles used for validation.'
                       '\ndefault value: 15%%')

  tp.add_argument('-o', '--output',
                  action='store', dest='outdir', metavar='DIR',
                  type=str, default='.',
                  help='output directory for training files.'
                       '\ndefaults to current directory.')

  ts = tp.add_mutually_exclusive_group()

  ts.add_argument('-l', '--level',
                  action='store', dest='level', metavar='ID',
                  type=str, default='RootSegm',
                  help='Annotation level identifier.'
                       '\nchoices: {RootSegm, IRStruct}'
                       '\ndefault value: RootSegm')

  ts.add_argument('-m', '--model',
                  action='store', dest='model', metavar='H5',
                  type=str, default=None,
                  help='path to the pre-trained model.'
                       '\ndefault value: none')

  tp.add_argument('-v', '--validate',
                  action='store', dest='vfrac', metavar='N%',
                  type=int, default=30,
                  help='percentage of tiles to be used for validation.'
                       '\ndefault value: 30%%')

  tp.add_argument('image', nargs='*',
                  default=['*.jpg'],
                  help='plant root scan to be processed.'
                       '\ndefaults to JPEG files in the current directory.')

  # Subparser dedicated to prediction of mycorrhizal structures.
  pp = subparsers.add_parser('predict',
                             help='predicts AMF structures.',
                             formatter_class=RawTextHelpFormatter)

  pp.add_argument('-t', '--tile',
                  action='store', dest='edge',
                  type=int, default=40,
                  help='tile edge (in pixels) used for image segmentation.'
                       '\ndefault value: 40 pixels')

  pp.add_argument('-a', '--activation_map', action='store_true',
                  dest='generate_cams', default=False,
                  help='Generate class activation map (takes some time).'
                       '\ndefault value: False')

  pp.add_argument('-c', '--colormap',
                  action='store', dest='colormap', metavar='N',
                  type=int, default=cv2.COLORMAP_JET,
                  help='OpenCV colormap (see OpenCV documentation).'
                       '\ndefault value: 2 (cv2.COLORMAP_JET)')

  pp.add_argument('model', action='store', metavar='H5',
                  type=str, default=None,
                  help='path to the pre-trained model.')

  pp.add_argument('image', nargs='*',
                  default=['*.jpg'],
                  help='plant root scan to be processed.'
                       '\ndefaults to JPEG files in the current directory.')

  return main



def abspath(files):
    """Expand wildcards and return absolute paths to input files."""
    files = sum([glob.glob(x) for x in files], [])
    return [os.path.abspath(x) for x in files]



def get_input_files():
    """ This function analyses the input file list and retains
        images based on their MIME type (files must be either
        JPEG or TIFF). """
    raw_list = abspath(get('input_files'))
    valid_types = ['image/jpeg', 'image/tiff']
    images = [x for x in raw_list if mimetypes.guess_type(x)[0] in valid_types]
    print('* Number of valid input images: {}.'.format(len(images)))
    return images



def initialize():
    """ Here is CastANet initialization function. It parses command-line
        arguments, performs type-checking, then updates internal settings
        accordingly. """
    parser = build_argumentp()
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
        set('fraction', par.vfrac)
        set('level', par.level)
        set('model', par.model)
        set('outdir', par.outdir)
        set('vfrac', par.vfrac)
    else: # par.run_mode == 'predict'
        set('model', par.model)
        set('generate_cams', par.generate_cams)
        set('colormap', par.colormap)

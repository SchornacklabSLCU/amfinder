# CastANet - castanet_config.py

import os
import glob
import mimetypes
from argparse import ArgumentParser
from argparse import RawTextHelpFormatter

HEADERS = {
  'colonization': ['Y', 'N', 'X'],
  'arb_vesicles': ['A', 'V', 'N', 'X'],
  'all_features': ['A', 'V', 'I', 'E', 'H', 'R', 'X']
}

# CastANet settings.
PAR = {
    'run_mode': None,
    'level': None,
    'model': None,
    'tile_edge': None,
    'model_input_size': 62,
    'input_files': None,
    'batch_size': None,
    'drop': None,
    'epochs': None,
    'vfrac': None,
    'header': HEADERS['colonization'],
    'outdir': None,
    'monitors': {
        'csv_logger': None,
        'early_stopping': None,
        'reduce_lr_on_plateau': None,
        'model_checkpoint': None,
    }
}



def get(s):
  """ This function retrieves a value based on its identifier. Identifiers
      get searched in general settings, then among Keras callback monitors.
      Search is case-insensitive. The function returns None when the
      identifier does not exist. """
  s = s.lower()
  if s in PAR:
    return PAR[s]
  elif s in PAR['monitors']:
    return PAR['monitors'][s]
  else:
    print('WARNING: Unknown parameter {}'.format(s))
    return None



def set(s, x, create=False):
  """ This function updates the value associated with an identifier.
      Identifiers get searched in general settings, then among Keras
      callback monitors. Search is case-insensitive. If the identifier
      does not exist, the function creates a new (id, value) pair if
      the optional parameter <create> equals True, or prints a warning
      message. No change occurs if the provided value is None. """
  if x is not None:
    s = s.lower()
    if s in PAR:
      PAR[s] = x
      if s == 'level':
        PAR['header'] = HEADERS[x]
    elif s in PAR['monitors']:
      PAR['monitors'][s] = x
    elif create:
      PAR[s] = x
    else:
      print('WARNING: Unknown parameter {}'.format(s))



def build_argument_parser():
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
  t_parser = subparsers.add_parser('train',
                                   help='learns how to identify AMF structures.',
                                   formatter_class=RawTextHelpFormatter)

  t_parser.add_argument('-t', '--tile',
                        action='store', dest='edge',
                        type=int, default=40,
                        help='tile edge (in pixels) used for image segmentation.'
                             '\ndefault value: 40 pixels')

  t_parser.add_argument('-b', '--batch',
                        action='store', dest='batch_size', metavar='NUM',
                        type=int, default=32,
                        help='training batch size.'
                             '\ndefault value: 32')

  t_parser.add_argument('-d', '--drop',
                        action='store', dest='dfrac', metavar='N%',
                        type=int, default=50,
                        help='percentage of background tiles to be skipped.'
                             '\ndefault value: 50%%')

  t_parser.add_argument('-e', '--epochs',
                        action='store', dest='epochs', metavar='NUM',
                        type=int, default=100,
                        help='number of epochs to run.'
                             '\ndefault value: 100')

  t_parser.add_argument('-f', '--fraction',
                        action='store', dest='vfrac', metavar='N%',
                        type=int, default=15,
                        help='output directory for training files.'
                             '\ndefaults to current directory.')

  t_parser.add_argument('-o', '--output',
                        action='store', dest='outdir', metavar='DIR',
                        type=str, default='.',
                        help='output directory for training files.'
                             '\ndefaults to current directory.')

  t_source = t_parser.add_mutually_exclusive_group()

  t_source.add_argument('-l', '--level',
                        action='store', dest='level', metavar='ID',
                        type=str, default='colonization',
                        help='Annotation level identifier.'
                             '\nchoices: {colonization, arb_vesicles, all_features}'
                             '\ndefault value: colonization')

  t_source.add_argument('-m', '--model',
                        action='store', dest='model', metavar='H5',
                        type=str, default=None,
                        help='path to the pre-trained model.'
                             '\ndefault value: none')

  t_parser.add_argument('-v', '--validate',
                        action='store', dest='vfrac', metavar='N%',
                        type=int, default=30,
                        help='percentage of tiles to be used for validation.'
                             '\ndefault value: 30%%')

  t_parser.add_argument('image', nargs='*',
                        default=['*.jpg'],
                        help='plant root scan to be processed.'
                             '\ndefault value: *jpg')

  # Subparser dedicated to prediction of mycorrhizal structures.
  p_parser = subparsers.add_parser('predict',
                                   help='predicts AMF structures.',
                                   formatter_class=RawTextHelpFormatter)

  p_parser.add_argument('-t', '--tile',
                        action='store', dest='edge',
                        type=int, default=40,
                        help='tile edge (in pixels) used for image segmentation.'
                             '\ndefault value: 40 pixels')

  p_parser.add_argument('model', action='store', metavar='H5',
                        type=str, default=None,
                        help='path to the pre-trained model.')

  p_parser.add_argument('image', nargs='*',
                        default=['*.jpg'],
                        help='plant root scan to be processed.'
                             '\ndefault value: *jpg')

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
    parser = build_argument_parser()
    par = parser.parse_known_args()[0]

    # Main arguments.
    set('run_mode', par.run_mode)
    set('tile_edge', par.edge)
    set('input_files', par.image)
    # Sub-parser specific arguments.
    if par.run_mode == 'train':
        set('batch_size', par.batch_size)
        set('drop', par.dfrac)
        set('epochs', par.epochs)
        set('fraction', par.vfrac)
        set('level', par.level)
        set('model', par.model)
        set('outdir', par.outdir)
        set('vfrac', par.vfrac)
    else: # par.run_mode == 'predict'
        set('model', par.model)    

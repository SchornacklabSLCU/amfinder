# CastANet - castanet_config.py

import os
import json
from argparse import ArgumentParser, RawTextHelpFormatter

HEADERS = {
  'colonization': ['Y', 'N', 'X'],
  'arb_vesicles': ['A', 'V', 'N', 'X'],
  'all_features': ['A', 'V', 'I', 'E', 'H', 'R', 'X']
}

PAR = {
  'run_mode': None,
  'source_tile_edge': None,
  'input_files': None,
  'batch_size': None,
  'drop_background': None,  
  'epochs': None,
  'fraction': None,
  'weights': None,
  # Things to change.
  'header': HEADERS['colonization'],
  'name': ['Colonized', 'Non-colonized', 'Background'],
  'curr': '',
  'level': None,
  'output_tile_edge': 62,
  'monitors': {
    'csv_logger': None,
    'early_stopping': None,
    'reduce_lr_on_plateau': None,
    'model_checkpoint': None,
  },
  'outdir': 'output',
}


def get(s):
  if s in PAR:
    return PAR[s]
  elif s in PAR['monitors']:
    return PAR['monitors'][s]
  else:
    print('WARNING: Unknown parameter {}'.format(s))
    return None


def set(s, x, create=False):
  if x is not None:
    if s in PAR:
      PAR[s] = x
      if s == 'level':
        PAR['header'] = HEADERS[s]
    elif s in PAR['monitors']:
      PAR['monitors'][s] = x
    elif create:
      PAR[s] = x
    else:
      print('WARNING: Unknown parameter {}'.format(s))



def build_argument_parser():
  main = ArgumentParser(description='CastANet command-line arguments.',
                        allow_abbrev=False,
                        formatter_class=RawTextHelpFormatter)

  main.add_argument('-t', '--tile',
                    action='store', dest='edge',
                    type=int, default=40,
                    help='tile edge, in pixels.'
                         '\ndefault value: 40 pixels')

  subparsers = main.add_subparsers(dest='run_mode', required=True,
                                   help='action to be performed.')

  # Training subparser.
  t_parser = subparsers.add_parser('train',
                                   help='learns how to identify AMF structures.',
                                   formatter_class=RawTextHelpFormatter)
 
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

  t_parser.add_argument('-v', '--validate',
                        action='store', dest='vfrac', metavar='N%',
                        type=int, default=30,
                        help='percentage of tiles to be used for validation.'
                             '\ndefault value: 30%%')

  # Prediction subparser.
  p_parser = subparsers.add_parser('predict',
                                   help='predicts AMF structures.',
                                   formatter_class=RawTextHelpFormatter)

  h5 = os.path.join('weights', 'castanet_{}.h5')
  p_parser.add_argument('-w', '--weights',
                        action='store', dest='weights', metavar='H5',
                        type=str, default=h5,
                        help='path to the pre-trained neural network.'
                             '\ndefault value: "{}"'.format(h5))

  main.add_argument('image', nargs='*',
                    default=['*.jpg'],
                    help='plant root scan to be processed.'
                         '\ndefault value: *jpg')

  return main



def initialize():
  parser = build_argument_parser()
  par = parser.parse_known_args()[0]

  # Main arguments.
  set('run_mode', par.run_mode)
  set('source_tile_edge', par.edge)
  set('input_files', par.image)
  if par.run_mode == 'train':
    set('batch_size', par.batch_size)
    set('drop_background', par.dfrac) 
    set('epochs', par.epochs)
    set('fraction', par.vfrac)
  else:
    set('weights', par.weights)

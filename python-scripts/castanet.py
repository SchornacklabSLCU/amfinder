# CastANet - castanet.py

import os
# Disables tensorflow messages/warnings.
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import sys
import keras
import mimetypes 

import castanet_core as cCore
import castanet_model as cModel
import castanet_train as cTrain
import castanet_config as cConfig
import castanet_predict as cPredict



def get_input_files():
  """ This function analyses the input file list and retains
      images based on their MIME type (files must be either
      JPEG or TIFF). """
  print('* Retrieving input images.')
  raw_list = cCore.abspath(cConfig.get('input_files'))
  valid_types = ['image/jpeg', 'image/tiff']
  return [x for x in raw_list if mimetypes.guess_type(x)[0] in valid_types]



def load_cnn():
  """ This function loads a pre-trained model (for re-training
      or prediction) or creates a fresh untrained model (for
      training only). It terminates the program if CastANet
      launched in prediction mode, and the provided h5 file
      is not available. """
  path = cConfig.get('model')
  if path is not None and os.path.isfile(path):
    print('* Loading a pre-trained model.')
    return keras.models.load_model(path)
  elif cConfig.get('run_mode') == 'train':
    print('* Creates an untrained model.')
    cnn = cModel.get()
    cnn.summary()
    return cnn
  else: # No h5 file and cConfig.get('run_mode') == 'predict'
    print('ERROR: Pre-trained model {} not found'.format(name))
    sys.exit(2)



if __name__ == '__main__':
  cConfig.initialize()
  input_files = get_input_files()
  cnn = load_cnn() 
  if cConfig.get('run_mode') == 'train':
    cTrain.run(cnn, input_files)
  else: # cConfig.get('run_mode') == 'predict'
    cPredict.run(cnn, input_files)   

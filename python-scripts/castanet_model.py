# CastANet - castanet_model.py

from keras.models import Sequential
from keras.layers import Conv2D
from keras.layers import MaxPooling2D
from keras.layers import Flatten
from keras.layers import Dropout
from keras.layers import Dense
from keras.initializers import he_uniform

import castanet_config as cConfig



def core_model(input_shape):
  """ This function builds the core models, i.e. the successive
      convolutions and maximum pooling, as well as the hidden dense
      layers. The output layer is left undefined and will be tuned
      to fit the annotation level (see functions below). """
  model = Sequential()                                 # 62
  model.add(Conv2D(32, kernel_size=3, name='CONV-1',
                   input_shape=input_shape, activation='relu',
                   kernel_initializer=he_uniform()))   # 60
  model.add(Conv2D(32, kernel_size=3, name='CONV-2',
                   input_shape=input_shape, activation='relu',
                   kernel_initializer=he_uniform()))   # 58
  model.add(Conv2D(32, kernel_size=3, name='CONV-3',
                   input_shape=input_shape, activation='relu',
                   kernel_initializer=he_uniform()))   # 56
  model.add(MaxPooling2D(pool_size=2, name='MAXP-1'))  # 28
  model.add(Conv2D(64, kernel_size=3, name='CONV-4',
                   activation='relu',
                   kernel_initializer=he_uniform()))   # 26
  model.add(Conv2D(64, kernel_size=3, name='CONV-5',
                   activation='relu',
                   kernel_initializer=he_uniform()))   # 24
  model.add(MaxPooling2D(pool_size=2, name='MAXP-2'))  # 12
  model.add(Conv2D(128, kernel_size=3, name='CONV-6',
                   activation='relu',
                   kernel_initializer=he_uniform()))   # 10
  model.add(Conv2D(128, kernel_size=3, name='CONV-7',
                   activation='relu',
                   kernel_initializer=he_uniform()))   #  8
  model.add(MaxPooling2D(pool_size=2, name='MAXP-3'))  #  4
  model.add(Conv2D(128, kernel_size=3, name='CONV-8',
                   activation='relu',
                   kernel_initializer=he_uniform()))   #  2
  model.add(MaxPooling2D(pool_size=2, name='MAXP-4'))  #  1
  model.add(Flatten(name='FLAT'))
  model.add(Dense(64, activation='relu', name='DENSE-1',
    kernel_initializer=he_uniform()))
  model.add(Dropout(0.3, name='DROP-1'))
  model.add(Dense(16, activation='relu', name='DENSE-2',
    kernel_initializer=he_uniform()))
  model.add(Dropout(0.2, name='DROP-2'))
  return model



def colonization(input_shape):
  """ This function returns a simple model for the less precise level
      of annotation, i.e. 'colonization', which has three mutually 
      exclusive categories: colonized, non-colonized, and background.
      As a result, the final layer uses categorical cross-entropy and
      softmax activation. """
  model = core_model(input_shape)
  model.add(Dense(3, activation='softmax', name='DENSE-3',
                  kernel_initializer=he_uniform()))
  model.compile(optimizer='adam',
                loss='categorical_crossentropy',
                metrics=['acc'])
  return model



def arb_vesicles(input_shape):
  """ This function returns a slightly more elaborate model for the
      intermediate level of annotation, i.e. 'arb_vesicles' which has
      four categories: arbuscules, vesicles, non-colonized roots, and
      background. As a result, the final layer uses binary
      cross-entropy and sigmoid activation. """
  model = core_model(input_shape)
  model.add(Dense(4, activation='sigmoid', name='DENSE-3',
                  kernel_initializer=he_uniform()))
  model.compile(optimizer='adam',
                loss='binary_crossentropy',
                metrics=['acc'])
  return model



def get_input_shape(level):
  """ This function retrieves the input shape corresponding to
      the desired annotation level. """
  if level == 'colonization':
    return (62, 62, 3)
  elif level == 'arb_vesicles':
    return (62, 62, 3)
  else: # level == 'all_features'
    return (236, 236, 3)


def get():
  """ This function returns a fresh compiled neural network that
      is ready for training. """
  level = cConfig.get('level')
  input_shape = get_input_shape(level) 
  if id == 'colonization':
    return colonization(input_shape)
  elif id == 'arb_vesicles':
    return arb_vesicles(input_shape)
  elif id == 'all_features':
    print('WARNING: Not implemented yet')
    return None
  else:
    print('WARNING: Unknown annotation level {}'.format(level))
    return None

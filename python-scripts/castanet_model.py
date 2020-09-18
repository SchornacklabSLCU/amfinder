# CastANet - castanet_model.py

from keras.initializers import he_uniform
from keras.models import Sequential
from keras.layers import Conv2D, MaxPooling2D, Flatten, Dropout, Dense


def core_model(input_shape):
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


# Simple mode (colonization): colonized, non-colonized, background.
# Categories are mutually exclusive, therefore we use categorical
# crossentropy and softmax activation.
def colonization(input_shape):
  model = core_model(input_shape)
  model.add(Dense(3, activation='softmax', name='DENSE-3',
                  kernel_initializer=he_uniform()))
  model.compile(optimizer='adam',
                loss='categorical_crossentropy',
                metrics=['acc'])
  return model


# Intermediate mode, with arbuscules and vesicles, non-colonized, background.
# Two categories at least can be combined, therefore we use binary
# crossentropy and sigmoid activation.
def arb_vesicles(input_shape):
  model = core_model(input_shape)
  model.add(Dense(4, activation='sigmoid', name='DENSE-3',
                  kernel_initializer=he_uniform()))
  model.compile(optimizer='adam',
                loss='binary_crossentropy',
                metrics=['acc'])
  return model


def from_string(id, input_shape):
  if id == 'colonization':
    return colonization(input_shape)
  elif id == 'arb_vesicles':
    return arb_vesicles(input_shape)
  elif id == 'all_features':
    print('WARNING: Not implemented yet')
    return None
  else:
    print('WARNING: Unknown identifier {id}')
    return None

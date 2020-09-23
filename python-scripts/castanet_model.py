# CastANet - castanet_model.py

import os
import sys

import keras
from keras.models import Sequential
from keras.layers import Conv2D
from keras.layers import MaxPooling2D
from keras.layers import Flatten
from keras.layers import Dropout
from keras.layers import Dense
from keras.initializers import he_uniform

import castanet_config as cConfig

NO_PRETRAINED_MODEL = 20
INVALID_MODEL_SHAPE = 21



def core_model(input_shape):
    """ This function builds the core models, i.e. the successive
      convolutions and maximum pooling, as well as the hidden dense
      layers. The output layer is left undefined and will be tuned
      to fit the annotation level (see functions below). """

    model = Sequential()

    # Input size: 62 pixels; output_size: 60 pixels        126->124
    model.add(Conv2D(32, kernel_size=3, name='C1', input_shape=input_shape,
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 60 pixels; output_size: 58 pixels        124->122
    model.add(Conv2D(32, kernel_size=3, name='C2',
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 58 pixels; output_size: 56 pixels        122->120
    model.add(Conv2D(32, kernel_size=3, name='C3',
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 56 pixels; output_size: 28 pixels        120->60
    model.add(MaxPooling2D(pool_size=2, name='M1'))

    # Input size: 28 pixels; output_size: 26 pixels         60->58
    model.add(Conv2D(64, kernel_size=3, name='C4',
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 26 pixels; output_size: 24 pixels         58->56
    model.add(Conv2D(64, kernel_size=3, name='C5',
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 24 pixels; output_size: 12 pixels         56->28
    model.add(MaxPooling2D(pool_size=2, name='M2'))

    # Input size: 12 pixels; output_size: 10 pixels         28->26
    model.add(Conv2D(128, kernel_size=3, name='C6',
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 10 pixels; output_size: 08 pixels         26->24
    model.add(Conv2D(128, kernel_size=3, name='C7',
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 08 pixels; output_size: 04 pixels         24->12
    model.add(MaxPooling2D(pool_size=2, name='M3'))

    # Input size: 04 pixels; output_size: 02 pixels         12->10
    model.add(Conv2D(128, kernel_size=3, name='C8',
                     activation='relu', kernel_initializer=he_uniform()))

    # Input size: 02 pixels; output_size: 01 pixels         10->5
    # TODO: replace with average pooling?
    model.add(MaxPooling2D(pool_size=2, name='M4'))

    model.add(Flatten(name='F'))

    model.add(Dense(64, activation='relu', name='H1',
                    kernel_initializer=he_uniform()))

    model.add(Dropout(0.3, name='D1'))

    model.add(Dense(16, activation='relu', name='H2',
                    kernel_initializer=he_uniform()))

    model.add(Dropout(0.2, name='D2'))

    return model



def colonization(input_shape):
    """ This function returns a simple model for the less precise level
      of annotation, i.e. 'colonization', which has three mutually 
      exclusive categories: colonized, non-colonized, and background.
      As a result, the final layer uses categorical cross-entropy and
      softmax activation. """

    model = core_model(input_shape)

    model.add(Dense(3, activation='softmax', name='O',
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

    model.add(Dense(4, activation='sigmoid', name='O',
                    kernel_initializer=he_uniform()))

    model.compile(optimizer='adam',
                  loss='binary_crossentropy',
                  metrics=['acc'])

    return model



def get_input_shape(level):
    """ Retrieves the input shape corresponding to the given
        annotation level. """

    if level == 'colonization':

        cConfig.set('model_input_size', 62)
        return (62, 62, 3)

    elif level == 'arb_vesicles':

        cConfig.set('model_input_size', 62)
        return (62, 62, 4)

    else:

        cConfig.set('model_input_size', 224)
        return (224, 224, 7)



def create():
    """ Returns a fresh model corresponding to the defined
        annotation level. """

    level = cConfig.get('level')
    input_shape = get_input_shape(level) 

    if level == 'colonization':

        return colonization(input_shape)

    elif level == 'arb_vesicles':

        return arb_vesicles(input_shape)

    elif level == 'all_features':

        print('WARNING: Not implemented yet')
        return None

    else:

        print('WARNING: Unknown annotation level {}'.format(level))
        return None



def pre_trained(path):
    """ Loads a pre-trained model and updates the annotation level
        according to its input shape. """

    print('* Loading a pre-trained model.')
    
    # Loads model.
    model = keras.models.load_model(path)   
    dim = model.layers[0].input_shape
    
    x = dim[1] # tile width
    y = dim[2] # tile height
    z = dim[3] # number of annotation classes

    if x != y:
    
        print(f'ERROR: Input shape ({x}x{y} pixels) is rectangular.')
        sys.exit(INVALID_MODEL_SHAPE)

    else:
    
        # Usual values are 62 pixels for colonization and arb_vesicles,
        # and 224 pixels for all_features.
        cConfig.set('model_input_size', x)

    if z == 3:

        cConfig.set('level', 'colonization')

    elif z == 4:

        cConfig.set('level', 'arb_vesicles')

    elif z == 7:

        cConfig.set('level', 'all_features')

    else:

        # Here we have no option but to raise an error and exit.
        # Pre-trained models must have a valid input shape.
        print(f'ERROR: Pre-trained model has {dim} dimensions.')
        sys.exit(INVALID_MODEL_SHAPE)

    return model



def load():
    """ Loads a pre-trained model, or creates a new one when the
        application runs in training mode. """

    path = cConfig.get('model')

    if cConfig.get('run_mode') == 'predict':

        if path is not None and os.path.isfile(path):

            return pre_trained(path)

        else:

            # Here we have no option but to raise an error and exit.
            # A pre-trained model is required to perform predictions.
            print('ERROR: Please provide a pre-trained model.')
            sys.exit(NO_PRETRAINED_MODEL)

    else:

        if path is not None and os.path.isfile(path):

            return pre_trained(path)

        else:

            print('* Creates an untrained model.')
            return create()

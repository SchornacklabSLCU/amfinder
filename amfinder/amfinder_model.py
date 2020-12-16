# AMFinder - amfinder_model.py

import os
import keras

from keras.layers import Input
from keras.layers import Conv2D
from keras.layers import MaxPooling2D
from keras.layers import Flatten
from keras.layers import Dense
from keras.layers import Dropout
from keras.models import Model
from keras.initializers import he_uniform

import amfinder_log as AMFlog
import amfinder_config as AMFcfg



def convolutions():
    """ Builds convolution blocks. """

    kc = 32
    input_layer = Input(shape=(126, 126, 3))

    # Convolution block 1: 126x126 -> 120x120
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C11')(input_layer)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C12')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C13')(x)

    x = MaxPooling2D(pool_size=2, name='M1')(x)

    kc *= 2

    # Convolution block 2: 60x60 -> 56x56
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C21')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C22')(x)

    x = MaxPooling2D(pool_size=2, name='M2')(x)

    kc *= 2

    # Convolution block 3: 28x28 -> 24x24
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C31')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C32')(x)

    x = MaxPooling2D(pool_size=2, name='M3')(x)

    # Last convolution: 12x12 -> 10x10
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C4')(x)

    # Final size: 5x5
    x = MaxPooling2D(pool_size=2, name='M4')(x)
    flatten = Flatten(name='F')(x)

    return (input_layer, flatten)



def fc_layers(x, label, count=1, activation='sigmoid'):
    """ Builds fully connected layers (with dropout). """

    x = Dense(64, kernel_initializer=he_uniform(),
              activation='relu', name='D1')(x)

    x = Dropout(0.3)(x)

    x = Dense(16, kernel_initializer=he_uniform(),
              activation='relu', name='D2')(x)

    x = Dropout(0.2)(x)

    output = Dense(count, activation=activation, name=label)(x)

    return output



def new_root_segmentation_network():
    """ Builds a single-label, multi-class classifier to discriminate
        colonized (Y) and non-colonized (N) roots, and background (X). """

    input_layer, flatten = convolutions()
    output_layer = fc_layers(flatten, 'RS', count=3, activation='softmax')

    model = Model(inputs=input_layer,
                  outputs=output_layer,
                  name='RootSegm')

    model.compile(loss='categorical_crossentropy',
                  optimizer='adam',
                  metrics=['acc'])

    return model



def new_myc_structures_network():
    """ Builds a multi-label, single-class classifier to identify
        arbuscules (A), vesicles (V) and intraradical hyphae (IH). """

    input_layer, flatten = convolutions()
    output_layers = [fc_layers(flatten, lbl) for lbl in AMFcfg.get('header')]

    model = Model(inputs=input_layer,
                  outputs=output_layers,
                  name='IRStruct')

    model.compile(loss='binary_crossentropy',
                  optimizer='adam',
                  metrics=['acc'])

    return model



def load():
    """ Loads a pre-trained network, or creates a new one. """

    path = AMFcfg.get('model')
    level = AMFcfg.get('level')

    # A pre-trained network file is available.
    if path is not None and os.path.isfile(path):
    
        print('* Pre-trained network: {}'.format(os.path.basename(path)))
        return keras.models.load_model(path)

    else:

        # Creates a new network if running in training mode.
        if AMFcfg.get('run_mode') == 'train':
        
            print('* Creates a new, untrained network.')

            if level == 1:

                return new_root_segmentation_network()

            else:

                return new_myc_structures_network()

        
        else: # cannot run predictions without a pre-trained model.
        
            AMFlog.error('A pre-trained model is required in prediction mode',
                       exit_code=AMFlog.ERR_NO_PRETRAINED_MODEL)

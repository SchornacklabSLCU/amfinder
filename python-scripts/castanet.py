# castanet overall colonization script.

import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import keras
import random
import pickle
import mimetypes 
import numpy as np
import pandas as pd

from sklearn.model_selection import train_test_split

import castanet_core as core
import castanet_plot as plot
import castanet_model as model
import castanet_config as cfg
import castanet_predict as pred
import castanet_segmentation as segm

from keras.preprocessing.image import ImageDataGenerator
from keras.callbacks import CSVLogger, EarlyStopping, ReduceLROnPlateau, ModelCheckpoint

XY = ['row', 'col']

def draw_training_history(history):
  """ Determines the last epoch, initialize plotting, and produce graphs. """
  es_epoch = cfg.get('early_stopping').stopped_epoch
  epochs = es_epoch + 1 if es_epoch > 0 else cfg.get('epochs')
  x_range = np.arange(0, epochs)
  plot.initialize()
  plot.draw(history, epochs, 'Loss', x_range, 'loss', 'val_loss')
  plot.draw(history, epochs, 'Accuracy', x_range, 'acc', 'val_acc')


def get_input_files():
  print('* Retrieving input images.')
  raw_list = core.abspath(cfg.get('input_files'))
  valid_types = ['image/jpeg', 'image/tiff']
  return [x for x in raw_list if mimetypes.guess_type(x)[0] in valid_types]


def load_tiles_and_annotations(input_file_list):
  print('* Loading tiles and annotations.')
  tiles = pd.DataFrame()
  for img_path in input_file_list:
    noext = os.path.splitext(img_path)[0]
    cfg.set('current', os.path.basename(noext))
    print('    - File {}'.format(CConfig.current()))
    image = keras_image.load_img(img_path, color_mode='rgb', target_size=None)
    tbl_path = noext + ".tsv"
    annot = pd.read_table(tbl_path)
    headers = cfg.get('header')
    annot['Tile'] = annot[XY].apply(lambda x: segm.tile(image, x[0], x[1]), axis=1)
    annot = annot[annot['Tile'].notnull()]
    annot['Tag'] = annot[headers].values.tolist()
    annot = annot.drop(columns=(XY + headers))
    tiles = tiles.append(annot)  
  annot = pd.Series(tiles['Tag'])
  hot_labels = np.asarray(annot)
  return (tiles, hot_labels)


def get_training_datasets(tiles, hot_labels):
  print('* Preparing training and validation datasets.')
  random.seed(42)
  x_train_list, y_train_list = segm.drop_background(tiles, hot_labels)
  y_train_raw = np.array(y_train_list, np.uint8)
  preprocess = lambda x: x / 255.0
  x_train_raw = preprocess(np.array(x_train_list, np.float32))
  return train_test_split(
      x_train_raw,
      y_train_raw,
      test_size=cfg.get('fraction'),
      random_state=42)


def load_cnn():
  cnn_file = os.path.join('weights', 'castanet_{}.h5'.format(cfg.get('level')))
  cnn_path = os.path.abspath(cnn_file)
  if os.path.isfile(cnn_path):
    print('* Loading a previously trained neural network.')
    return keras.models.load_model(cnn_path)
  else:
    print('* Loading a new (untrained) neural network.')
    edge = cfg.get('output_tile_edge')
    cnn = model.from_string('colonization', (edge, edge, 3))
    cnn.summary()
    return cnn




def get_callbacks():
  callbacks = []
  cb = CSVLogger('training_Logger.csv', separator=',', append=False)
  cfg.set('csv_logger', cb)
  callbacks.append(cb)
  cb = EarlyStopping(monitor='val_loss', min_delta=0, patience=10, verbose=1,
                     mode='auto', restore_best_weights=True)
  cfg.set('early_stopping', cb)
  callbacks.append(cb)
  cb = ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=2,
                         verbose=1, min_lr=0.001)
  cfg.set('reduce_lr_on_plateau', cb)
  callbacks.append(cb)
  cb = ModelCheckpoint(filepath='best_model.h5', monitor='val_loss',
                       save_best_only=True)
  cfg.set('model_checkpoint', cb)
  callbacks.append(cb)
  return callbacks


def get_data_generator(data_augmentation=False):
  if (data_augmentation):
    # We use only minimal data augmentation since rotation and shift can result
    # in signal loss (especially when structures are on the edges).
    return ImageDataGenerator(horizontal_flip=True, vertical_flip=True)
  else:
    return ImageDataGenerator()


if __name__ == '__main__':

  cfg.initialize()
  input_files = get_input_files()
  r_mode = cfg.get('run_mode')
  cnn = load_cnn()
  
  if r_mode == 'train':
    os.chdir(CConfig.output_directory())
    #SETTINGS['dir'] = CCore.now()
    #os.mkdir(SETTINGS['dir'])
    #os.chdir(SETTINGS['dir'])
    tiles, hot_labels = load_tiles_and_annotations(input_files)
    x_train, x_check, y_train, y_check = get_training_datasets(tiles, hot_labels)
    train_generator = get_data_generator(data_augmentation=True)
    valid_generator = get_data_generator()
    bs = CConfig.batch_size()
    steps_per_epoch = len(x_train) // bs
    H = cnn.fit(
      train_generator.flow(x_train, y_train, batch_size=bs),
      steps_per_epoch=steps_per_epoch,
      epochs=CConfig.epochs(),
      validation_data=valid_generator.flow(x_check, y_check, batch_size=bs),
      validation_steps=len(x_check) // bs,
      callbacks=get_callbacks(), verbose=1)
    with open("history.bin", 'wb') as handle:
      pickle.dump(H.history, handle, protocol=pickle.HIGHEST_PROTOCOL)
    #cnn.save("flatbed_model.h5")
    draw_training_history(H.history)

  elif r_mode == 'predict':
    pred.run(cnn, input_files)

  else:
    print('WARNING: Unknown running mode {}'.format(r_mode))     

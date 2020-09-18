# CastANet - castanet_train.py

import os
import random
import pickle
import numpy as np
import pandas as pd

from keras.callbacks import CSVLogger
from keras.callbacks import EarlyStopping
from keras.callbacks import ModelCheckpoint
from keras.callbacks import ReduceLROnPlateau
from keras.preprocessing.image import load_img
from keras.preprocessing.image import ImageDataGenerator

from sklearn.model_selection import train_test_split

import castanet_plot as cPlot
import castanet_config as cConfig


XY = ['row', 'col']



def get_data_generator(data_augmentation=False):
  """ Creates a data generator which applies or not data augmentation.
      Data augmentation is kept to a minimum (ie horizontal and vertical
      flip) to avoid signal loss when mycorrhizal structures occur near
      tile edges. """
  if data_augmentation:
    return ImageDataGenerator(horizontal_flip=True, vertical_flip=True)
  else:
    return ImageDataGenerator()



# TODO: Improve this function to load data from a ZIP file!
def load_tiles_and_annotations(input_file_list):
  print('* Loading tiles and annotations.')
  tiles = pd.DataFrame()
  for img_path in input_file_list:
    noext = os.path.splitext(img_path)[0]
    cConfig.set('image', os.path.basename(noext))
    print('    - File {}'.format(cConfig.get('image')))
    image = load_img(img_path, color_mode='rgb', target_size=None)
    # Loads the annotation table.
    tbl_path = "{}.tsv".format(noext)
    annot = pd.read_table(tbl_path)
    headers = cConfig.get('header')
    annot['Tile'] = annot[XY].apply(lambda x: segm.tile(image, x[0], x[1]), axis=1)
    annot = annot[annot['Tile'].notnull()]
    annot['Tag'] = annot[headers].values.tolist()
    annot = annot.drop(columns=(XY + headers))
    tiles = tiles.append(annot)  
  annot = pd.Series(tiles['Tag'])
  hot_labels = np.asarray(annot)
  return (tiles, hot_labels)



def get_training_datasets(tiles, hot_labels):
  """"""
  print('* Preparing training and validation datasets.')
  random.seed(42)
  x_train_list, y_train_list = segm.drop_background(tiles, hot_labels)
  y_train_raw = np.array(y_train_list, np.uint8)
  preprocess = lambda x: x / 255.0
  x_train_raw = preprocess(np.array(x_train_list, np.float32))
  return train_test_split(
      x_train_raw,
      y_train_raw,
      test_size=cConfig.get('fraction'),
      random_state=42)



def get_callbacks():
  callbacks = []

  cb = CSVLogger('training_Logger.csv',
           separator=',',
           append=False)
  cConfig.set('csv_logger', cb)
  callbacks.append(cb)

  cb = EarlyStopping(monitor='val_loss',
           min_delta=0,
           patience=10,
           verbose=1,
           mode='auto',
           restore_best_weights=True)
  cConfig.set('early_stopping', cb)
  callbacks.append(cb)

  cb = ReduceLROnPlateau(monitor='val_loss',
           factor=0.2,
           patience=2,
           verbose=1,
           min_lr=0.001)
  cConfig.set('reduce_lr_on_plateau', cb)
  callbacks.append(cb)

  cb = ModelCheckpoint(filepath='best_model.h5',
           monitor='val_loss',
           save_best_only=True)
  cConfig.set('model_checkpoint', cb)
  callbacks.append(cb)

  return callbacks



def draw_training_history(history):
  """ Determines the last epoch, initialize plotting, and produce graphs. """
  es_epoch = cConfig.get('early_stopping').stopped_epoch
  epochs = es_epoch + 1 if es_epoch > 0 else cConfig.get('epochs')
  x_range = np.arange(0, epochs)
  cPlot.initialize()
  cPlot.draw(history, epochs, 'Loss', x_range, 'loss', 'val_loss')
  cPlot.draw(history, epochs, 'Accuracy', x_range, 'acc', 'val_acc')



def run(cnn, input_files):
  #os.chdir(cConfig.get('outdir'))
  #cConfig.set('dir', core.now())
  #os.mkdir(SETTINGS['dir'])
  #os.chdir(SETTINGS['dir'])
  tiles, hot_labels = load_tiles_and_annotations(input_files)
  x_train, x_check, y_train, y_check = get_training_datasets(tiles, hot_labels)
  train_generator = get_data_generator(data_augmentation=True)
  valid_generator = get_data_generator()
  batch = cConfig.get('batch_size')
  steps_per_epoch = len(x_train) // batch
  H = cnn.fit(
    train_generator.flow(x_train, y_train, batch_size=batch),
    steps_per_epoch=steps_per_epoch,
    epochs=cConfig.get('epochs'),
    validation_data=valid_generator.flow(x_check, y_check, batch_size=batch),
    validation_steps=len(x_check) // batch,
    callbacks=get_callbacks(), verbose=1)
  with open("history.bin", 'wb') as handle:
    pickle.dump(H.history, handle, protocol=pickle.HIGHEST_PROTOCOL)
  #cnn.save("flatbed_model.h5")
  draw_training_history(H.history)


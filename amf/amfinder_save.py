# AMFinder - amfinder_save.py
#
# MIT License
# Copyright (c) 2021 Edouard Evangelisti, Carl Turner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

""" 
Model and prediction saving.

Functions
------------

:function now: Returns the current date/time.
:function training_data: Saves training weights, history and plots.
:function get_zip_info: Creates a ZIP information object.
:function save_settings: Saves image settings.
:function prediction_table: Saves or append predictions to an archive.
"""

import os
import io
import json
import h5py
import pickle
import datetime
import numpy as np
import amfinder_zipfile as zf
import matplotlib as plt

import amfinder_log as AmfLog
import amfinder_plot as AmfPlot
import amfinder_model as AmfModel
import amfinder_config as AmfConfig

CORRUPTED_ARCHIVE = 30
IMG_SETTINGS = 'settings.json'



def now():
    """
    Returns the current date/time in a format suitable
    for use as file name.
    """

    return datetime.datetime.now().isoformat(sep='_')



def training_data(history, model):
    """
    Saves training weights, history and plots.
    
    :param history: Training history data.
    :param model: The CNN model that was used for training.
    """

    zipf = now() + '_training.zip'
    zipf = os.path.join(AmfConfig.get('outdir'), zipf)

    with zf.ZipFile(zipf, 'w') as z:

        # Saves history.
        data = pickle.dumps(history, protocol=pickle.HIGHEST_PROTOCOL)
        z.writestr('history.bin', data)

        # Saves model. BytesIO is not yet available.
        with h5py.File('any', mode='w', 
                       driver='core', backing_store=False) as h5file:
        
            model.save(h5file)
            h5file.flush()
            bin_data = h5file.id.get_file_image()
            z.writestr(AmfConfig.string_of_level() + '.h5', bin_data)

        # Saves plots.
        early = AmfConfig.get('early_stopping').stopped_epoch
        epochs = early + 1 if early > 0 else AmfConfig.get('epochs')
        x_range = np.arange(0, epochs)

        AmfPlot.initialize()
        data = AmfPlot.draw(history, epochs, 'Loss', x_range, 
                            'loss', 'val_loss')
        z.writestr('loss.png', data.getvalue())

        if AmfConfig.get('level') == 1:

            data = AmfPlot.draw(history, epochs, 'Accuracy', x_range, 
                                'acc', 'val_acc')
            z.writestr('accuracy.png', data.getvalue())
        
        else:
        
            for cls in AmfConfig.get('header'):
            
                label = 'arbuscules'
                
                if cls == 'V':
                
                    label = 'vesicles'
                    
                elif cls == 'H':
                
                    label = 'hyphae'
            
                data = AmfPlot.draw(history, epochs, 
                                    f'Accuracy ({label})', x_range,
                                    f'{cls}_acc', 
                                    f'val_{cls}_acc')

                z.writestr(f'{cls}_accuracy.png', data.getvalue())

                data = AmfPlot.draw(history, epochs, 
                                    f'Loss ({label})', x_range,
                                    f'{cls}_loss', 
                                    f'val_{cls}_loss')

                z.writestr(f'{cls}_loss.png', data.getvalue())




def get_zip_info(path, comment):
    """
    Creates a ZIP information object for a given file.
    
    :param path: Path to the file to create.
    :param comment: String to use as comment for the ZIP file.
    """

    a = datetime.datetime.today()
    now = (a.year, a.month, a.day, a.hour, a.minute, a.second)
    zi = zf.ZipInfo(filename=path, date_time=now)
    zi.external_attr = (0o644 & 0xFFFF) << 16  # Unix attributes
    zi.comment = f'{comment}'.encode()
    zi.compress_type = zf.ZIP_DEFLATED
    return zi



def save_sr_image(uniq, z, sr_image):
    buf = io.BytesIO()
    plt.image.imsave(buf, sr_image, format='jpg')
    comment = os.path.basename(AmfConfig.get('generator'))
    zi = get_zip_info(f'sr/{uniq}.jpg', comment)
    z.writestr(zi, buf.getvalue())



def save_settings(z):
    """
    Saves image settings (currently, only tile size).
    
    :param z: ZIP archive.
    """

    # Level 2 predictions require settings.json.
    # Make sure not the duplicate file if it exists.
    if AmfConfig.get('level') == 1 and IMG_SETTINGS not in z.namelist():

        with z.open(IMG_SETTINGS, mode='w') as s:
            edge = AmfConfig.get('tile_edge')
            data = '{"tile_edge": %d}' % (edge)
            s.write(data.encode())



def prediction_table(results, sr_image, path):
    """
    Saves or append predictions to an archive.
    
    :param results: annotation table to save.
    :param sr_image: high-resolution image.
    :param path: path to the ZIP archive.
    """

    if results is not None:

        zipf = '{}.zip'.format(os.path.splitext(path)[0])
        print(f'    - saving as {zipf}... ', end='')

        uniq = now()
        data = results.to_csv(sep='\t', encoding='utf-8', index=False)
        tsv = os.path.join('predictions', f'{uniq}.tsv')

        if os.path.isfile(zipf):

            if zf.is_zipfile(zipf):

                with zf.ZipFile(zipf, 'a') as z:
                    save_settings(z)
                    level = AmfConfig.string_of_level()
                    zi = get_zip_info(tsv, level)
                    z.writestr(zi, data)
                    z.comment = b'{level}'                   
                    
                    if sr_image is not None:
                        save_sr_image(uniq, z, sr_image)
        
            else:

                AmfLog.error('Corrupted archive',
                             AmfLog.ERR_CORRUPTED_ARCHIVE)
    
        else:

            with zf.ZipFile(zipf, 'w') as z:
                save_settings(z)
                zi = get_zip_info(tsv, AmfConfig.string_of_level())
                z.writestr(zi, data)
                if sr_image is not None:
                    save_sr_image(uniq, z, sr_image)

        print('OK')

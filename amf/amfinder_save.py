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

"""

import os
import io
import sys
import json
import h5py
import pickle
import datetime
import numpy as np
import zipfile as zf
import matplotlib as plt

import amfinder_plot as AmfPlot
import amfinder_model as AmfModel
import amfinder_config as AmfConfig

CORRUPTED_ARCHIVE = 30



def string_of_level():

    if AmfConfig.get('level') == 1:
    
        return AmfModel.COLONIZATION_NAME
        
    else:
    
        return AmfModel.MYC_STRUCTURES_NAME



def now():
    """ Returns the current date/time in a format 
        suitable for use as file name. """

    return datetime.datetime.now().isoformat(sep='_')



def training_data(history, model):
    """ Saves training weights, history and plots. """

    zipf = now() + '_training.zip'

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
            z.writestr(string_of_level() + '.h5', bin_data)

        # Saves plots.
        early = AmfConfig.get('early_stopping').stopped_epoch
        epochs = early + 1 if early > 0 else AmfConfig.get('epochs')
        x_range = np.arange(0, epochs)

        AmfPlot.initialize()
        data = AmfPlot.draw(history, epochs, 'Loss', x_range, 'loss', 'val_loss')
        z.writestr('loss.png', data.getvalue())

        if AmfConfig.get('level') == 1:

            data = AmfPlot.draw(history, epochs, 'Accuracy', x_range, 'acc', 'val_acc')
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
    a = datetime.datetime.today()
    now = (a.year, a.month, a.day, a.hour, a.minute, a.second)
    zi = zf.ZipInfo(filename=path, date_time=now)
    zi.external_attr = (0o644 & 0xFFFF) << 16  # Unix attributes
    zi.comment = f'{comment}'.encode()
    zi.compress_type = zf.ZIP_DEFLATED
    return zi



def save_cams(uniq, z, cams):

    level = string_of_level()
    for label, image in zip(AmfConfig.get('header'), cams):
        buf = io.BytesIO()
        plt.image.imsave(buf, image, format='jpg')
        zi = get_zip_info(f'activations/{uniq}.{label}.jpg', label)
        z.writestr(zi, buf.getvalue())
        z.comment = f'{label}'.encode()



def save_settings(z):
    """ Saves tile size. """

    # Prediction of mycorrhizal structures requires settings.json.
    # There is no need to create the file again.
    if AmfConfig.get('level') == 1:

        with z.open('settings.json', mode='w') as s:
            edge = AmfConfig.get('tile_edge')
            data = '{"tile_edge": %d}' % (edge)
            s.write(data.encode())



def prediction_table(results, cams, path):
    """ Saves or append predictions to an archive. """

    # TODO: check whether None may happen.
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
                    level = string_of_level()
                    zi = get_zip_info(tsv, level)
                    z.writestr(zi, data)
                    z.comment = b'{level}'                   
                    
                    if cams is not None:
                        save_cams(uniq, z, cams)
        
            else:

                print('FAILED')
                sys.exit(CORRUPTED_ARCHIVE)
    
        else:

            with zf.ZipFile(zipf, 'w') as z:
                save_settings(z)
                zi = get_zip_info(tsv, string_of_level())
                z.writestr(zi, data)
                if cams is not None:
                    save_cams(uniq, z, cams)

        print('OK')

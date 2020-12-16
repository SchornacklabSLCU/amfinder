# CastANet - amfinder_save.py

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

import amfinder_plot as cPlot
import amfinder_config as cConfig

CORRUPTED_ARCHIVE = 30



def string_of_level():

    if cConfig.get('level') == 1:
    
        return 'RootSegm'
        
    else:
    
        return 'IRStruct'



def now():
    """ Returns the current date/time in a format 
        suitable for use as file name. """

    return datetime.datetime.now().isoformat(sep='_')



def training_data(history, model):
    """ Saves training weights, history and plots. """

    zipf = os.path.join(cConfig.get('outdir'), now() + '_training.zip')
    
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
        early = cConfig.get('early_stopping').stopped_epoch
        epochs = early + 1 if early > 0 else cConfig.get('epochs')
        x_range = np.arange(0, epochs)

        cPlot.initialize()
        data = cPlot.draw(history, epochs, 'Loss', x_range, 'loss', 'val_loss')
        z.writestr('loss.png', data.getvalue())

        data = cPlot.draw(history, epochs, 'Accuracy', x_range, 'acc', 'val_acc')
        z.writestr('accuracy.png', data.getvalue())



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
    for label, image in zip(cConfig.get('header'), cams):
        buf = io.BytesIO()
        plt.image.imsave(buf, image, format='jpg')
        zi = get_zip_info(f'activations/{uniq}.{label}.jpg', label)
        z.writestr(zi, buf.getvalue())
        z.comment = f'{label}'.encode()



def save_settings(z):
    """ Saves tile size. """

    # IRStruct predictions require settings.json.
    # There is no need to create the file again.
    if cConfig.get('level') == 1:

        with z.open('settings.json', mode='w') as s:
            edge = cConfig.get('tile_edge')
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

# CastANet - castanet_save.py

import os
import io
import sys
import h5py
import pickle
import datetime
import numpy as np
import zipfile as zf
import matplotlib as plt

import castanet_plot as cPlot
import castanet_config as cConfig

CORRUPTED_ARCHIVE = 30


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
            z.writestr(cConfig.get('level') + '.h5', bin_data)

        # Saves plots.
        early = cConfig.get('early_stopping').stopped_epoch
        epochs = early + 1 if early > 0 else cConfig.get('epochs')
        x_range = np.arange(0, epochs)

        cPlot.initialize()
        data = cPlot.draw(history, epochs, 'Loss', x_range, 'loss', 'val_loss')
        z.writestr('loss.png', data.getvalue())

        data = cPlot.draw(history, epochs, 'Accuracy', x_range, 'acc', 'val_acc')
        z.writestr('accuracy.png', data.getvalue())



def save_cams(uniq, z, cams):

    for label, image in zip(cConfig.get('header'), cams):
        buf = io.BytesIO()
        plt.image.imsave(buf, image)
        z.writestr(f'cams/{uniq}_{label}.png',  buf.getvalue())



def prediction_table(results, cams, path):
    """ Saves or append predictions to an archive. """

    # TODO: check whether None may happen.
    if results is not None:

        zipf = '{}.zip'.format(os.path.splitext(path)[0])
        print(f'    - saving as {zipf}... ', end='')

        uniq = now()
        data = results.to_csv(sep='\t', encoding='utf-8', index=False)
        tsv = os.path.join('predictions', uniq + '.tsv')

        if os.path.isfile(zipf):

            if zf.is_zipfile(zipf):

                with zf.ZipFile(zipf, 'a') as z:
                    z.comment = cConfig.get('level').encode('utf-8')
                    z.writestr(tsv, data)
                    if cams is not None:
                        save_cams(uniq, z, cams)
        
            else:

                print('FAILED')
                sys.exit(CORRUPTED_ARCHIVE)
    
        else:

            with zf.ZipFile(zipf, 'w') as z:
                z.comment = cConfig.get('level').encode('utf-8')
                z.writestr(tsv, data)
                if cams is not None:
                    save_cams(uniq, z, cams)

        print('OK')

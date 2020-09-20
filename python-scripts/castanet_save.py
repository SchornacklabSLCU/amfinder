# CastANet - castanet_save.py

import os
import sys
import datetime
import zipfile as zf

import castanet_config as cConfig

CORRUPTED_ARCHIVE = 30


def now():
    """ Returns the current date/time in a format 
        suitable for use as file name. """

    return datetime.datetime.now().isoformat(sep='_')



def archive(results, path):
    """ Saves or append predictions to an archive. """

    # TODO: check whether None may happen.
    if results is not None:

        data = results.to_csv(sep='\t', encoding='utf-8', index=False)
        zipf = '{}.zip'.format(os.path.splitext(path)[0])
        tsv = os.path.join('predictions', now() + '.tsv')

        if os.path.isfile(zipf):

            if zf.is_zipfile(zipf):

                print('    -> saved as {}'.format(zipf))
                with zf.ZipFile(zipf, 'a') as z:
                    z.comment = cConfig.get('level').encode('utf-8')
                    z.writestr(tsv, data)

            else:

                print(f'ERROR: Corrupted archive {zipf}')
                sys.exit(CORRUPTED_ARCHIVE)
    
        else:

            print('    -> saved as {}'.format(zipf))
            with zf.ZipFile(zipf, 'w') as z:
                z.comment = cConfig.get('level').encode('utf-8')
                z.writestr(tsv, data)

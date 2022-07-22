# AMFinder - amfinder_convert.py
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


import io
import os
import json
import imagesize
import numpy as np
import pandas as pd
#import zipfile as zf
# Reference: https://stackoverflow.com/a/69115481
# Local version of zipfile to get access to <remove>.
import amfinder_zipfile as zf
import amfinder_log as AmfLog
import amfinder_save as AmfSave
import amfinder_train as AmfTrain
import amfinder_config as AmfConfig
import amfinder_diagnose as AmfDiagnose


NROWS = None
NCOLS = None


def initialize_size(path, zfile):
    """
    Retrieve the number of rows and columns based on image and tile sizes.
    """
    tile_size = None
    width, height = imagesize.get(path)

    with zf.ZipFile(zfile, 'r') as z:
        data = z.read(AmfSave.IMG_SETTINGS).decode('utf-8')
        tile_size = json.loads(data)['tile_edge']

    global NROWS, NCOLS
    assert tile_size is not None
    NCOLS = width // tile_size
    NROWS = height // tile_size



def preds_to_python_annot_1(path, preds):
    """
    Convert level 1 predictions to Python annotations.
    """

    # Only one file, nothing special to choose.
    preds = io.StringIO(preds)
    preds = pd.read_csv(preds, sep='\t')

    # Get the predictions for automatic conversion.
    coord = preds[['row', 'col']]
    preds = AmfDiagnose.remove_coordinates(preds)
    preds = preds.to_numpy()

    # Perform the conversion, ignoring ties.
    conv = np.zeros_like(preds)
    conv[np.arange(len(preds)), preds.argmax(1)] = 1
    conv = conv.astype(np.uint8)

    print(os.path.basename(path) + '\t' + 
          '\t'.join([str(x) for x in np.sum(conv, axis=0)]))

    conv = pd.DataFrame(data=conv, columns=AmfConfig.get('header'))

    # Generate the final table. 
    return pd.concat([coord, conv], axis=1)



def preds_to_python_annot_2(path, preds):
    """
    Convert level 2 predictions to Python annotations.
    """

    # Only one file, nothing special to choose.
    preds = io.StringIO(preds)
    preds = pd.read_csv(preds, sep='\t')

    # Get the predictions for automatic conversion.
    coord = preds[['row', 'col']]
    preds = AmfDiagnose.remove_coordinates(preds)
    preds = preds.to_numpy()

    # Perform the conversion, ignoring ties.
    conv = np.zeros_like(preds)
    conv[preds >= AmfConfig.get('threshold')] = 1
    
    conv = conv.astype(np.uint8)
    

    print(os.path.basename(path) + '\t' + 
          '\t'.join([str(x) for x in np.sum(conv, axis=0)]))

    header = AmfConfig.get('header')
    conv = pd.DataFrame(data=conv, columns=header)

    # Generate the final table. 
    final = pd.concat([coord, conv], axis=1)

    # Remove the columns without annotations
    final = final.loc[(final[header].sum(axis=1) != 0), ]

    return final


def python_annot_to_ocaml_1(out, zfile):
    """
    Convert level 1 predictions to OCaml annotations.
    """
    
    mat1 = np.zeros((NROWS, NCOLS)).astype('<U1')
    mat2 = np.zeros((NROWS, NCOLS)).astype('<U1')
    
    header = AmfConfig.get('header')
    out = out.reset_index()

    for _, row in out.iterrows():
        r = row['row']
        c = row['col']
        mat1[r, c] = header[np.argmax(row[header])]
        mat2[r, c] = '' # this one will remain empty.

    with zf.ZipFile(zfile, 'a') as z:

        d1 = pd.DataFrame(mat1).to_csv(sep='\t', encoding='utf-8',
                                       index=False, header=False,
                                       mode='a', line_terminator='')
        zi = AmfSave.get_zip_info('annotations/col.caml', 1)
        # There is still a trailing character at the end of the csv text.
        z.writestr(zi, d1[:-1])
        d2 = pd.DataFrame(mat2).to_csv(sep='\t', encoding='utf-8',
                                       index=False, header=False,
                                       mode='a', line_terminator='')
        zi = AmfSave.get_zip_info('annotations/myc.caml', 0)
        # There is still a trailing character at the end of the csv text.
        z.writestr(zi, d2[:-1])



def python_annot_to_ocaml_2(out, zfile):
    """
    Convert level 2 predictions to OCaml annotations.
    """

    mat2 = np.zeros((NROWS, NCOLS), str).astype('<U4')
    
    header = AmfConfig.get('header')
    out = out.reset_index()

    for _, row in out.iterrows():
        r = row['row']
        c = row['col']
        indices = [i for i, x in enumerate(row[header]) if x == 1]
        mat2[r, c] = ''.join(sorted([header[i] for i in indices]))

    with zf.ZipFile(zfile, 'a') as z:
        z.remove('annotations/myc.caml')
        d2 = pd.DataFrame(mat2).to_csv(sep='\t', encoding='utf-8',
                                       index=False, header=False,
                                       mode='a', line_terminator='')
        zi = AmfSave.get_zip_info('annotations/myc.caml', 0)
        # There is still a trailing character at the end of the csv text.
        z.writestr(zi, d2[:-1])



def preds_to_python_annot(path, preds):
    """
    Convert predictions to Python annotations.
    """
    if AmfConfig.get('level') == 1:
    
        return preds_to_python_annot_1(path, preds)
    
    else:
    
        return preds_to_python_annot_2(path, preds)



def python_annot_to_ocaml(out, zfile):
    """
    Convert and save predictions to OCaml annotations.
    """
    if AmfConfig.get('level') == 1:
    
        python_annot_to_ocaml_1(out, zfile)
    
    else:
    
        python_annot_to_ocaml_2(out, zfile)

    update_archive(out, zfile)


def update_archive(out, zfile):
    """
    Save annotations in Python format.
    """
    with zf.ZipFile(zfile, 'a') as z:

        data = out.to_csv(sep='\t', encoding='utf-8', index=False,
                          mode='a', line_terminator='')
        zi = AmfSave.get_zip_info(AmfConfig.tsv_name(), AmfConfig.string_of_level())
        z.writestr(zi, data[:-1])



def create_annotations(path, zfile):

    preds = []

    with zf.ZipFile(zfile, 'r') as z:

        if AmfConfig.tsv_name() in z.namelist():

            AmfLog.info(f'Skipping {path} as annotations already exist')
            return

        for x in z.namelist():

            if os.path.dirname(x) == 'predictions':
            
                if z.getinfo(x).comment.decode('utf-8') == AmfConfig.string_of_level():
            
                    preds.append(x)

        if preds == []:
        
            AmfLog.info(f'Skipping {path} as no predictions could be found')

        elif len(preds) == 1:
            
                data = z.read(preds[0]).decode('utf-8')
                out = preds_to_python_annot(path, data)
                python_annot_to_ocaml(out, zfile)

        else:

            AmfLog.info(f'Skipping {path} as <amf predict> does not \
                    support multiple prediction files.')




def run(input_images):

    print('Image\t' + '\t'.join(AmfConfig.human_redable_header()))

    for path in input_images:
    
        # Make sure the image comes with a valid zip file.
        zfile = AmfTrain.get_zipfile(path)

        if not zf.is_zipfile(zfile):

            AmfLog.warning(f'File {path} has no associated zip file.')
       
        initialize_size(path, zfile)
        create_annotations(path, zfile)
        
        

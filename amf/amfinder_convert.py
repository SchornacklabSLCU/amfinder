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


# Caution: EXPERIMENTAL FEATURE
# This module implements unsupervised conversions of <amf> predictions to 
# annotations. Use at your own risks!

import io
import os
import numpy as np
import pandas as pd
import zipfile as zf
import amfinder_save as AmfSave
import amfinder_train as AmfTrain
import amfinder_config as AmfConfig
import amfinder_diagnose as AmfDiagnose



def preds_to_python_annot_1(path, preds):

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



def python_annot_to_ocaml_1(out, zfile):
    """
    Ocamlbrowser requires another type of file.
    """
    
    rows = out['row'].max()
    cols = out['col'].max()

    mat1 = np.zeros((rows + 1, cols + 1)).astype('<U1')
    mat2 = np.zeros((rows + 1, cols + 1)).astype('<U1')
    
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
        zi = AmfSave.get_zip_info('annotations/col.caml', True)
        # There is still a trailing character at the end of the csv text.
        z.writestr(zi, d1[:-1])
        d2 = pd.DataFrame(mat2).to_csv(sep='\t', encoding='utf-8',
                                       index=False, header=False,
                                       mode='a', line_terminator='')
        zi = AmfSave.get_zip_info('annotations/myc.caml', False)
        # There is still a trailing character at the end of the csv text.
        z.writestr(zi, d2[:-1])



def create_annotations(path, zfile):

    out = None
    preds = []

    with zf.ZipFile(zfile, 'r') as z:

        for elt in z.namelist():

            if os.path.dirname(elt) == 'predictions':
            
                preds.append(elt)

        if preds == []:
        
            print(f'Skipping {path}: predictions not found')

        # TODO: find a better way...
        elif len(preds) == 1: # colonisation.

            if 'col.tsv' in z.namelist():

                print(f'Skipping {path}: annotations already exist')

            else:
            
                data = z.read(preds[0]).decode('utf-8')
                out = preds_to_python_annot_1(path, data)
                python_annot_to_ocaml_1(out, zfile)

        elif len(preds) == 2: # mycorrhizal structures.

            pass


    if out is not None:

        with zf.ZipFile(zfile, 'a') as z:
            data = out.to_csv(sep='\t', encoding='utf-8', index=False)
            zi = AmfSave.get_zip_info('col.tsv', 'col')
            z.writestr(zi, data)



def run(input_images):

    print('WARNING: You are using an experimental feature.')
    print('         It is still under active development and may contain bugs.')

    print('Image\tM+\tM−\tOther')

    for path in input_images:
    
        # Make sure the image comes with a valid zip file.
        zfile = AmfTrain.get_zipfile(path)

        if not zf.is_zipfile(zfile):

            print(f'Skipping {path}: zip file not found.')
       
        create_annotations(path, zfile)

        # Make sure predictions are available.
        
        
        

# AMFinder - amfinder_diagnose.py
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
Computes diagnostic metrics (precision and specificity) to assess network 
performance.

Global
------------
:dict SENSITIVITY: Dictionary containing the true positive counts.
:dict SPECIFICITY: Dictionary containing the true negative counts.

Functions
------------
:function dict_of_header: Builds a dictionary using the active class header.
:function initialize: Initialises SENSITIVITY and SPECIFICITY.
:function remove_coordinates: Removes columns 'row' and 'col' from a dataframe.
:function as_annotations: Performs automatic conversions.

"""

import os
import numpy as np
import pandas as pd
from contextlib import redirect_stdout

import amfinder_log as AmfLog
import amfinder_train as AmfTrain
import amfinder_config as AmfConfig
import amfinder_predict as AmfPredict

ACCURACY = {}
SENSITIVITY = {}
SPECIFICITY = {}



def dict_of_header():
    """
    Builds a dictionary using the current annotation classes as keys.
    """
    return {key : [] for key in AmfConfig.get('header')}



def initialize():
    """
    """
    global ACCURACY
    global SENSITIVITY
    global SPECIFICITY
    ACCURACY = dict_of_header()
    SENSITIVITY = dict_of_header()
    SPECIFICITY = dict_of_header()



def remove_coordinates(df):
    """
    Removes columns 'row' and 'col' from a dataframe.
    
    :param df: the dataframe to process.
    :return: a processed dataframe.
    :retype: Pandas dataframe.
    """

    return df.drop(['row', 'col'], axis=1)



def as_annotations(preds, threshold=0.5):
    """
    Perform automatic conversion of predictions to annotations.
    Level 1: the highest value is used as annotation.
    Level 2: any value >= 0.5 is considered as annotation.
    
    :param preds: prediction table.
    :param threshold: threshold for level 2 conversions (default: 0.5).
    :return: an annotation table.
    :rtype: Pandas dataframe.
    """


    preds = remove_coordinates(preds)
    preds = preds.to_numpy()

    if AmfConfig.get('level') == 1:

        conv = np.zeros_like(preds)
        # Note: ties are ignored.
        conv[np.arange(len(preds)), preds.argmax(1)] = 1

    else: # AmfConfig.get('level') == 2:

        conv = np.where(preds >= threshold, 1, 0)    

    conv = conv.astype(np.uint8)
    return pd.DataFrame(data=conv, columns=AmfConfig.get('header'))



def compare(preds, path):
    """
    Compares annotations and computer predictions.
    """

    global ACCURACY
    global SENSITIVITY
    global SPECIFICITY
    
    if len(SENSITIVITY) == 0:
    
        initialize()
    
    annot = AmfTrain.import_annotations(path)

    if annot is None:
    
        base = os.path.basename(path)
        AmfLog.warning('Image {base} has no annotations')

    else:

        annot = remove_coordinates(annot)
        preds = as_annotations(preds)

        for cls in AmfConfig.get('header'):
       
            p_count = 0     # positive annotation.
            n_count = 0     # negative annotation.
            tp_count = 0    # true positives.
            tn_count = 0    # true negatives.
            fp_count = 0    # false positives.
            fn_count = 0    # false negatives.
        
            for a, p in zip(annot.itertuples(), preds.itertuples()):
            
                if getattr(a, cls) == 1:
                
                    p_count += 1
                
                    if getattr(p, cls) == 1:
                
                        tp_count += 1
                    
                    else:
                    
                        fn_count += 1
                    
                else:
                
                    n_count += 1
                
                    if getattr(p, cls) == 0:
                
                        tn_count += 1
                        
                    else:
                    
                        fp_count += 1

            ACCURACY[cls].append(None if p_count + n_count == 0 else (tp_count + tn_count) / (p_count + n_count))
            SENSITIVITY[cls].append(None if p_count == 0 else tp_count / (tp_count + fn_count))
            SPECIFICITY[cls].append(None if n_count == 0 else tn_count / (tn_count + fp_count))



def run(input_images):
    """
    Print neural network diagnostic.
    """

    AmfPredict.run(input_images, postprocess=compare)

    cnn = 'CNN%d' % (AmfConfig.get('level'))
    path = os.path.join(AmfConfig.get('outdir'), f'{cnn}_diagnostic.tsv')

    with open(path, 'w') as sf:

        with redirect_stdout(sf):

            print('Group\tClass\tPercentage')

            for typ, dic in zip(['Accuracy', 'Sensitivity', 'Specificity'],
                                [ACCURACY, SENSITIVITY, SPECIFICITY]):
            
                for cls in AmfConfig.get('header'):
                
                    for x in dic[cls]:
                        
                        x = "NA" if x is None else x
                    
                        print(f'{typ}\t{cls}\t{x}')

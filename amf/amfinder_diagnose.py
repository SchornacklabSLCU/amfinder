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
Compute diagnostic metrics (accuracy, sensitivity, and specificity) and 
confusion matrices to assess network performance.

Global
------------
:dict SENSITIVITY: Dictionary containing the true positive counts.
:dict SPECIFICITY: Dictionary containing the true negative counts.

Functions
------------
:function text_of_list: Convert a string list to multiline text.
:function dict_of_header: Builds a dictionary using the active class header.
:function save_mispredicted_tile: Save a subset of mispredicted tiles.
:function get_index: Convert an integer list to string.
:function initialise: Initialises SENSITIVITY and SPECIFICITY.
:function remove_coordinates: Removes columns 'row' and 'col' from a dataframe.
:function as_annotations: Performs automatic conversions.
:function safe_ratio: Compute x/y if y != 0, or return NaN.
:function compare: Compare computer predictions to annotations for an image.
:function plot_confusion_matrix: Plot and save a confusion matrix.
:function run: Perform diagnostic analysis of the given network.

"""

import io
import os
import numpy as np
import pandas as pd
import amfinder_zipfile as zf
from PIL import Image
from contextlib import redirect_stdout

import amfinder_log as AmfLog
import amfinder_save as AmfSave
import amfinder_train as AmfTrain
import amfinder_config as AmfConfig
import amfinder_predict as AmfPredict
import amfinder_segmentation as AmfSegm

import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# Constants.
METRICS = ['Accuracy', 'Sensitivity', 'Specificity']
STRING_INDICES = ['0', '1', '3', '01', '03', '13', '013']
TICKS = [list(range(0, 3)), list(range(0, 7))]
LABELS = [['M+', 'M−', 'Other'],
          ['A', 'V', 'I', 'AV', 'AI', 'VI', 'AVI']]

# Global variables.
Z = None
ID = {}
MATRIX = None
ACCURACY = {}
SENSITIVITY = {}
SPECIFICITY = {}

TP_COUNT = None
TN_COUNT = None
FP_COUNT = None
FN_COUNT = None


def text_of_list(t):
    """
    Convert a string list to multiline text.
    """
    return '\n'.join(t)


def dict_of_header():
    """
    Builds a dictionary using the current annotation classes as keys.
    """
    return {key : [] for key in AmfConfig.get('header')}



def get_index(t):
    """
    Convert an integer list to string.
    """

    # Remove hyphopodia. This will be removed once we
    # acquire enough images to train AMFinder.
    t = np.setdiff1d(t, np.array([2]))

    elt = ''.join(map(str, t))

    return None if len(elt) == 0 else STRING_INDICES.index(elt)



def initialise():
    """
    Initialise dictionaries and confusion matrix.
    """

    global Z
    global ID
    global MATRIX
    global ACCURACY
    global SENSITIVITY
    global SPECIFICITY
    
    global TP_COUNT
    global TN_COUNT
    global FP_COUNT
    global FN_COUNT
    
    nclasses = len(AmfConfig.get('header'))
    TP_COUNT = [0] * nclasses   # True positives.
    FP_COUNT = [0] * nclasses   # False positives.
    TN_COUNT = [0] * nclasses   # True negatives.
    FN_COUNT = [0] * nclasses   # False negatives.

    # Initialise confusion matrices and tile counters.
    labels = LABELS[0]
    classes = 3

    if AmfConfig.get('level') == 2:

        labels = LABELS[1]
        classes = 7

    ID = {x : 0 for x in labels}
    MATRIX = [np.zeros(classes) for _ in range(0, classes)]

    # Initialise metrics.
    ACCURACY = dict_of_header()
    SENSITIVITY = dict_of_header()
    SPECIFICITY = dict_of_header()

    # Initialise archive.
    now = AmfSave.now()
    cnn = os.path.basename(AmfConfig.get('model'))
    zipf = f'{now}_{cnn}_diagnostic.zip'
    zipf = os.path.join(AmfConfig.get('outdir'), zipf)
    Z = zf.ZipFile(zipf, 'w')



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



def safe_ratio(x, y):

    return float('nan') if y == 0 else x / y



def save_mispredicted_tile(image, a, p, rc, samples_per_class=-1):
    """
    Save a subset of mispredicted tiles.
    """
    global ID

    level = AmfConfig.get('level')

    a = None if a is None else LABELS[level - 1][a]
    p = None if p is None else LABELS[level - 1][p]

    if p is not None and a is not None and \
       (samples_per_class <= 0 or ID[p] < samples_per_class):
    
        ID[p] += 1
        num = ID[p]
        img = Image.fromarray(AmfSegm.tile(image, rc[0], rc[1]))
        byt = io.BytesIO()   
        img.save(byt, 'PNG')
        path = f'mispredicted_tiles/p{p}_a{a}_{num:06d}.png'
        Z.writestr(path, byt.getvalue())



def compare(image, preds, path):
    """
    Compare annotations and computer predictions.
    This is the continuation function to be passed to AmfPredict.run
    """

    global Z
    global ID
    global MATRIX
    global ACCURACY
    global SENSITIVITY
    global SPECIFICITY

    global TP_COUNT
    global TN_COUNT
    global FP_COUNT
    global FN_COUNT


    if MATRIX is None:

        initialise()

    annot = AmfTrain.import_annotations(path)

    if annot is None:

        base = os.path.basename(path)
        AmfLog.warning('Image {base} has no annotations')

    else:

        coord = preds[['row', 'col']]
        annot = remove_coordinates(annot)
        preds = as_annotations(preds)

        # Convert tables to one-hot encoded vectors.
        annot_hot = annot.values.tolist()
        preds_hot = preds.values.tolist()

        if AmfConfig.get('level') == 1:

            # Get indices of active classes.
            annot_bin = np.argmax(annot_hot, axis=1)
            preds_bin = np.argmax(preds_hot, axis=1)

        else:

            # Get indices of all non-zero classes.
            annot_bin = [np.nonzero(x)[0] for x in annot_hot]
            preds_bin = [np.nonzero(x)[0] for x in preds_hot]

        nclasses = len(AmfConfig.get('header'))

        for a, p, rc in zip(annot_bin, preds_bin, coord.values.tolist()):

            if AmfConfig.get('level') == 1:

                MATRIX[a][p] += 1

                if p == a:

                    TP_COUNT[p] += 1

                    for x in range(0, nclasses):

                        if x != p:

                            TN_COUNT[x] += 1

                else:

                    save_mispredicted_tile(image, a, p, rc)

                    # The predicted class is a false positive.
                    FP_COUNT[p] += 1
                    # The expected class (annotation) is a false negative.
                    FN_COUNT[a] += 1
                    # The remaining class (neither p nor a) is a true negative.
                    TN_COUNT[3 - p - a] += 1

            else:

                a_idx = get_index(a)
                p_idx = get_index(p)

                if a_idx != p_idx:

                    save_mispredicted_tile(image, a_idx, p_idx, rc)

                # In some rare cases, computer predictions are
                # all < 0.5, resulting in empty prediction set.
                # Also, some cells may have received no annotation.
                if a_idx is not None and p_idx is not None:

                    MATRIX[a_idx][p_idx] += 1

                for i in range(0, nclasses):

                    if i in p: # class <i> is part of predictions.

                        if i in a: # class <i> is part of expected annotations.

                            TP_COUNT[i] += 1

                        else:

                            FP_COUNT[i] += 1

                    else: # class <i> is not part of predictions.

                        if i in a: # class <i> is part of expected annotations.

                            FN_COUNT[i] += 1

                        else:

                            TN_COUNT[i] += 1



def plot_confusion_matrix(cnn):
    """
    Generate and save a confusion matrix from the given counts.
    """

    global MATRIX

    # Ground truth normalisation.
    row_sums = np.asarray(MATRIX).sum(axis=1)
    MATRIX = MATRIX / row_sums[:, np.newaxis] * 100

    fig = plt.figure()
    ax = fig.add_subplot(111)

    cax = plt.imshow(MATRIX, cmap='cool')
    plt.clim(0, 100)
    fig.colorbar(cax)

    # Title and axes titles.
    plt.title(f'{cnn}', fontsize=16)
    plt.xlabel('Predictions', fontsize=14, fontweight='bold')
    plt.ylabel('Annotations', fontsize=14, fontweight='bold')

    ax.xaxis.set_major_locator(ticker.MultipleLocator(1))
    ax.yaxis.set_major_locator(ticker.MultipleLocator(1))

    level = AmfConfig.get('level') == 1

    # Ticks and labels.
    ax.set_xticks(TICKS[level - 1])
    ax.set_yticks(TICKS[level - 1])
    ax.set_xticklabels(LABELS[level - 1])
    ax.set_yticklabels(LABELS[level - 1])

    # Display values within the confusion matrix.
    for (a, p), z in np.ndenumerate(MATRIX):

        text_color = 'black' if z <= 50.0 else 'white'

        ax.text(p, a, '{:.1f}'.format(z),
                ha='center',
                va='center',
                fontsize=11,
                weight='bold',
                color=text_color)

    path = os.path.join(AmfConfig.get('outdir'), )
    byt = io.BytesIO()      
    plt.savefig(byt, format='jpg', dpi=300, pil_kwargs={'quality': 100})
    Z.writestr(f'{cnn}_confusion_matrix.jpg', byt.getvalue())



def run(input_images):
    """
    Print neural network diagnostic.
    """

    AmfPredict.run(input_images, postprocess=compare)

    for x, k in enumerate(AmfConfig.get('header')):

        ACCURACY[k].append(safe_ratio(TP_COUNT[x] + TN_COUNT[x],
                                      TP_COUNT[x] + FP_COUNT[x] +
                                      TN_COUNT[x] + FN_COUNT[x]))

        SENSITIVITY[k].append(safe_ratio(TP_COUNT[x],
                                         TP_COUNT[x] + FN_COUNT[x]))

        SPECIFICITY[k].append(safe_ratio(TN_COUNT[x],
                                         TN_COUNT[x] + FP_COUNT[x]))



    cnn = os.path.basename(AmfConfig.get('model'))

    # Metrics data.
    buffer = ['Group\tClass\tPercentage']
    for typ, dic in zip(METRICS, [ACCURACY,
                                  SENSITIVITY,
                                  SPECIFICITY]):

        for cls in AmfConfig.get('header'):

            for x in dic[cls]:

                x = "NA" if x is None else x

                buffer.append(f'{typ}\t{cls}\t{x}')

    Z.writestr(f'{cnn}_metrics.tsv', text_of_list(buffer))

    # Confusion matrix.
    plot_confusion_matrix(cnn)

    print('* Diagnostic data: {}'.format(Z.filename))
    Z.close()

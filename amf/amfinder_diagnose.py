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
:function get_index: Convert an integer list to string.
:function initialise: Initialises SENSITIVITY and SPECIFICITY.
:function remove_coordinates: Removes columns 'row' and 'col' from a dataframe.
:function as_annotations: Performs automatic conversions.
:function safe_ratio: Compute x/y if y != 0, or return NaN.
:function compare: Compare computer predictions to annotations for an image.
:function plot_confusion_matrix: Plot and save a confusion matrix.
:function run: Perform diagnostic analysis of the given network.

"""

import os
import numpy as np
import pandas as pd
from PIL import Image
from contextlib import redirect_stdout

import amfinder_log as AmfLog
import amfinder_train as AmfTrain
import amfinder_config as AmfConfig
import amfinder_predict as AmfPredict

import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

import amfinder_segmentation as AmfSegm

ID = 0
METRICS = ['Accuracy', 'Sensitivity', 'Specificity']
STRING_INDICES = ['0', '1', '3','01', '03', '13', '013']

LEVEL_1_TICKS = list(range(0, 3))
LEVEL_2_TICKS = list(range(0, 7))
LEVEL_1_LABELS = ['M+', 'M−', 'Other']
LEVEL_2_LABELS = ['A', 'V', 'I', 'AV', 'AI', 'VI', 'AVI']

MATRIX = None
ACCURACY = {}
SENSITIVITY = {}
SPECIFICITY = {}



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

    global MATRIX
    global ACCURACY
    global SENSITIVITY
    global SPECIFICITY

    nclasses = len(AmfConfig.get('header'))

    if AmfConfig.get('level') == 1:

        MATRIX = [np.zeros(nclasses) for _ in range(0, nclasses)]

    else:

        MATRIX = [np.zeros(7) for _ in range(0, 7)]

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



def safe_ratio(x, y):

    return float('nan') if y == 0 else x / y



def compare(image, preds, path):
    """
    Compare annotations and computer predictions.
    This is the continuation function to be passed to AmfPredict.run
    """

    global ID
    global MATRIX
    global ACCURACY
    global SENSITIVITY
    global SPECIFICITY

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
        tp_count = [0] * nclasses   # True positives.
        fp_count = [0] * nclasses   # False positives.
        tn_count = [0] * nclasses   # True negatives.
        fn_count = [0] * nclasses   # False negatives.

        for a, p, rc in zip(annot_bin, preds_bin, coord.values.tolist()):

            if AmfConfig.get('level') == 1:

                MATRIX[a][p] += 1

                if p == a:

                    tp_count[p] += 1

                    for x in range(0, nclasses):

                        if x != p:

                            tn_count[x] += 1

                else:

                    # Deactivated for the moment.
                    #ID += 1
                    #tile = AmfSegm.tile(image, rc[0], rc[1])
                    #pimg = Image.fromarray(tile)
                    #pimg.save(os.path.join(AmfConfig.get('outdir'),
                    #          f'mispredicted/p{p}a{a}_{ID:06d}.png'))

                    # The predicted class is a false positive.
                    fp_count[p] += 1
                    # The expected class (annotation) is a false negative.
                    fn_count[a] += 1
                    # The remaining class (neither p nor a) is a true negative.
                    tn_count[3 - p - a] += 1

            else:

                a_idx = get_index(a)
                p_idx = get_index(p)

                # Deactivated for the moment.
                #if a_idx != p_idx:
                
                #    ID += 1
                #    tile = AmfSegm.tile(image, rc[0], rc[1])
                #    pimg = Image.fromarray(tile)
                #    a_lbl = '0' if a_idx is None else LEVEL_2_LABELS[a_idx]
                #    p_lbl = '0' if p_idx is None else LEVEL_2_LABELS[p_idx]
                #    pimg.save(os.path.join(AmfConfig.get('outdir'),
                #              f'mispredicted/p{p_lbl}a{a_lbl}_{ID:06d}.png'))

                # In some rare cases, computer predictions are
                # all < 0.5, resulting in empty prediction set.
                # Also, some cells may have received no annotation.
                if a_idx is not None and p_idx is not None:

                    MATRIX[a_idx][p_idx] += 1

                for i in range(0, nclasses):

                    if i in p: # class <i> is part of predictions.

                        if i in a: # class <i> is part of expected annotations.

                            tp_count[i] += 1

                        else:

                            fp_count[i] += 1

                    else: # class <i> is not part of predictions.

                        if i in a: # class <i> is part of expected annotations.

                            fn_count[i] += 1

                        else:

                            tn_count[i] += 1


        for x, k in enumerate(AmfConfig.get('header')):

            ACCURACY[k].append(safe_ratio(tp_count[x] + tn_count[x],
                                          tp_count[x] + fp_count[x] +
                                          tn_count[x] + fn_count[x]))

            SENSITIVITY[k].append(safe_ratio(tp_count[x],
                                             tp_count[x] + fn_count[x]))

            SPECIFICITY[k].append(safe_ratio(tn_count[x],
                                             tn_count[x] + fp_count[x]))



def plot_confusion_matrix(cnn):
    """
    Generate and save a confusion matrix from the given counts.
    """

    fig = plt.figure()
    ax = fig.add_subplot(111)

    cax = plt.imshow(MATRIX, cmap='cool')
    fig.colorbar(cax)

    plt.title(f'{cnn}', fontsize=16)
    plt.xlabel('Annotations', fontsize=14, fontweight='bold')
    plt.ylabel('Predictions', fontsize=14, fontweight='bold')

    ax.xaxis.set_major_locator(ticker.MultipleLocator(1))
    ax.yaxis.set_major_locator(ticker.MultipleLocator(1))

    if AmfConfig.get('level') == 1:

        ax.set_xticks(LEVEL_1_TICKS)
        ax.set_yticks(LEVEL_1_TICKS)
        ax.set_xticklabels(LEVEL_1_LABELS)
        ax.set_yticklabels(LEVEL_1_LABELS)

    else:

        # Rotating X-axis labels for improved readability.
        # This is useful when using 4 annotation classes.
        plt.xticks(rotation=90)
        plt.tight_layout()

        ax.set_xticks(LEVEL_2_TICKS)
        ax.set_yticks(LEVEL_2_TICKS)
        ax.set_xticklabels(LEVEL_2_LABELS)
        ax.set_yticklabels(LEVEL_2_LABELS)

    for (i, j), z in np.ndenumerate(MATRIX):

        ax.text(j, i, '{:d}'.format(int(z)),
                ha='center',
                va='center',
                fontsize=8,
                color='black')

    path = os.path.join(AmfConfig.get('outdir'), f'{cnn}_confusion_matrix.jpg')
    plt.savefig(path, dpi=300, pil_kwargs={'quality': 100})

    print(f'* Confusion matrix: {path}')



def run(input_images):
    """
    Print neural network diagnostic.
    """

    AmfPredict.run(input_images, postprocess=compare)

    cnn = os.path.basename(AmfConfig.get('model'))
    path = os.path.join(AmfConfig.get('outdir'), f'{cnn}_diagnostic.tsv')

    with open(path, 'w') as sf:

        with redirect_stdout(sf):

            print('Group\tClass\tPercentage')

            for typ, dic in zip(METRICS, [ACCURACY,
                                          SENSITIVITY,
                                          SPECIFICITY]):

                for cls in AmfConfig.get('header'):

                    for x in dic[cls]:

                        x = "NA" if x is None else x

                        print(f'{typ}\t{cls}\t{x}')

    # Print a quick summary with average values.

    print('* Average values')

    for metric, data in zip(METRICS, [ACCURACY,
                                      SENSITIVITY,
                                      SPECIFICITY]):

        print(f'  {metric}')

        for cls in AmfConfig.get('header'):

            avg = np.nanmean(data[cls])

            print('  - Class %s: %.4f' % (cls, avg))

    print(f'* Diagnostic file: {path}')

    # No confusion matrix in level 2.
    if AmfConfig.get('level') == 1 or True:

        plot_confusion_matrix(cnn)

# CastANet suite - amfinder_log.py

""" Log Functions.

    Displays information, warnings, errors, and progress bars.

    Constants
    -----------
    ERR_INVALID_MODEL - Wrong Keras model.
    ERR_NO_PRETRAINED_MODEL - A pre-trained model is required but not provided.
    ERR_INVALID_MODEL_SHAPE - Wrong model input shape.
    ERR_INVALID_ANNOTATION_LEVEL - 
    ERR_MISSING_ARCHIVE - Cannot find the zip archive associated with an image.

    Functions
    -----------
    info -  print a message.
    warning - print a warning message.
    error - print an error message, and closes the application.
    progress_bar - displays a progress bar.

"""

import sys
import traceback



ERR_INVALID_MODEL = 40
ERR_NO_PRETRAINED_MODEL = 20
ERR_INVALID_MODEL_SHAPE = 21
ERR_INVALID_ANNOTATION_LEVEL = 22
ERR_MISSING_ARCHIVE = 30



def info(message, indent=0, **kwargs):
    """ Prints an message on standard output. """

    print(' ' * 4 * indent + f'INFO: {message}.', **kwargs)



def warning(message, indent=0, **kwargs):
    """ Prints a warning message on standard error. """

    print(' ' * 4 * indent + f'WARNING: {message}.', file=sys.stderr, **kwargs)



def error(message, exit_code, indent=0, **kwargs):
    """ Prints an error message on standard error and quits. """

    print(' ' * 4 * indent + f'ERROR: {message}.', file=sys.stderr, **kwargs)

    if exit_code is not None and exit_code != 0:

        sys.exit(exit_code)



def progress_bar(iteration, total, indent=0):
    """ Displays a progress bar. """

    percent = 100.0 * iteration / float(total)

    completed = round(50.0 * iteration / total)
    remaining = 50 - completed

    bar = '█' * completed + '-' * remaining

    print(' ' * 4 * indent + f'- processing |{bar}| {percent:.1f}%', end='\r')

    if iteration == total:

        print() # newline

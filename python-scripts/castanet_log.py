# CastANet suite - castanet_log.py

"""
CastANet log functions.

FUNCTIONS
    - info: print a message on standard output.
    - warning: print a warning message on standard error.
    - error: print an error message on standard error, and may terminate.
    - progress_bar: print a progress bar on standard output.
    
CONSTANTS
    - ERR_INVALID_MODEL: the provided Keras model is invalid.
    - ERR_NO_PRETRAINED_MODEL: no model, or the given model is not found.
    - ERR_INVALID_MODEL_SHAPE: the pre-trained model shape is not recognized.
"""

import sys
import traceback

ERR_INVALID_MODEL = 40
ERR_NO_PRETRAINED_MODEL = 20
ERR_INVALID_MODEL_SHAPE = 21



def info(message, indent=0, **kwargs):
    """
    Print an message on standard output.

    PARAMETERS
        - message: the information to be printed on standard output.
        - indent: indentation level (e.g. `1` means four white spaces).
        - kwargs: any other argument to be passed to `print`.

    No returned value.
    """

    print(' ' * 4 * indent + f'INFO: {message}.', **kwargs)



def warning(message, indent=0, **kwargs):
    """
    Print a warning message on standard error.
    
    PARAMETERS
        - message: the warning message to be printed on standard error.
        - indent: indentation level (e.g. `1` means four white spaces).
        - kwargs: any other argument to be passed to `print`.
    
    No returned value.
    """

    print(' ' * 4 * indent + f'WARNING: {message}.', file=sys.stderr, **kwargs)



def error(message, exit_code, indent=0, **kwargs):
    """
    Print an error message on standard error, and may terminate the application.

    PARAMETERS
        - message: the error message to be printed on standard error.
        - exit_code: application exit code (does not exit if `0` or `None`).
        - indent: indentation level (e.g. `1` means four white spaces).
        - kwargs: any other argument to be passed to `print`.

    No returned value.
    """

    print(' ' * 4 * indent + f'ERROR: {message}.', file=sys.stderr, **kwargs)

    if exit_code is not None and exit_code != 0:

        sys.exit(exit_code)



def progress_bar(iteration, total, indent=0):
    """
    Print a progress bar on standard output.
    
    PARAMETERS
        - iteration: the index of the current iteration.
        - total: the total number of iterations.
        - indent: indentation level (e.g. `1` means four white spaces).
    
    No returned value.
    """

    # Determine the percentage of progression.
    percent = 100.0 * iteration / float(total)

    # Generate ASCII progress bar.
    filled_length = round(50.0 * iteration / total)
    bar = '█' * filled_length + '-' * (50 - filled_length)

    print(' ' * 4 * indent + f'- processing |{bar}| {percent:.1f}%', end='\r')

    if iteration == total:

        print()

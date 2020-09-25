# CastANet - castanet_log.py

import sys
import traceback

class CastANetError:
    pass

ERR_INVALID_MODEL = 40


def progress_bar(iteration, total):
    """ Call in a loop to create terminal progress bar
        PARAMETERS
        iteration: int
            Current iteration.
        total: int
            Total iterations.
    """

    percent = ('{0:.1f}').format(100 * (iteration / float(total)))
    filled_length = int(50 * iteration // total)
    bar = '█' * filled_length + '-' * (50 - filled_length)

    print(f'\r    - processing |{bar}| {percent}%', end = '\r')

    if iteration == total: 
        print()



def info(message, indent=0, **kwargs):
    """
    Print an message on standard output.

    PARAMETERS
        - message: the information to print on standard output.
        - indent: message indentation level (e.g. `1` means four white spaces).
        - kwargs: any other argument to be passed to `print`.

    No returned value.
    """

    print(' ' * 4 * indent + f'INFO: {message}.', kwargs)



def warning(message):
    """ Print a warning message on standard error. """

    print(f'    WARNING: {message}.', file=sys.stderr)



def failwith(message, err_code):
    try:
        raise CastANetError(f'ERROR: {message}.')
    except:
        traceback.print_exc()
        sys.exit(err_code)

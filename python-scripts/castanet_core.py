# CastANet - castanet_core.py

import os
import glob
import datetime

def now():
  return datetime.datetime.now().isoformat(sep='_')

def abspath(files):
    """Expand wildcards and return absolute paths to input files."""
    files = sum([glob.glob(x) for x in files], [])
    return [os.path.abspath(x) for x in files]


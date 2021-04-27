#! /bin/bash

PYTHON="${PYTHON:-$(which python3)}"

$PYTHON -m pip install virtualenv

$PYTHON -m venv amfenv

source amfenv/bin/activate

# Note: this is important for tensorflow installation.
$PYTHON -m pip install --upgrade pip

$PYTHON -m pip install -r requirements.txt

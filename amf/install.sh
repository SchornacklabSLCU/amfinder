#! /bin/bash

PYTHON="$(which python3.7)"

$PYTHON -m pip install virtualenv

$PYTHON -m venv amfenv

source amfenv/bin/activate

python -m pip install --upgrade pip

python -m pip install -r requirements.txt
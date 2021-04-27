#! /bin/bash

$PYTHON -m pip install virtualenv

$PYTHON -m venv amfenv

source amfenv/bin/activate

$PYTHON -m pip install --upgrade pip

$PYTHON -m pip install -r requirements.txt

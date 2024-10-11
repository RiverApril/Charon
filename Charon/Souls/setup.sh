#!/usr/bin/env bash

set -e
python3 -m venv $1/pyenv

source $1/pyenv/bin/activate
python3 -m pip install pyspellchecker


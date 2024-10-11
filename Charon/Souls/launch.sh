#!/usr/bin/env bash

source $1/pyenv/bin/activate
cd $1
shift
python3 $@

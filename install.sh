#!/bin/bash

BIN_PATH=${1:-~/bin}
BIN_PATH=${BIN_PATH%/}

ln -s $PWD/scriptybase.sh $BIN_PATH/scriptybase

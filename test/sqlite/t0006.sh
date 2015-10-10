#!/bin/bash

### database correctly installed. One patch applied and modified

#set -xv
DIR=$1
SANDBOX_DIR=$2

scriptybase -t sqlite -d $DIR/test.db -r . -p $DIR --auto

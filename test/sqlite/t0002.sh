#!/bin/bash

### database correctly installed. No patches pending

#set -xv
DIR=$1
SANDBOX_DIR=$2

scriptybase -t sqlite -d $DIR/test.db -r . -p $DIR  --check
scriptybase -t sqlite -d $DIR/test.db -r . -p $DIR 

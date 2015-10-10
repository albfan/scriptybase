#!/bin/bash

### database not configured

DIR=$1
SANDBOX_DIR=$2
scriptybase -t sqlite -d $DIR/test.db -r . -p $DIR --check

#!/bin/bash

### database correctly installed. One patch manually applied

#set -xv
DIR=$1
SANDBOX_DIR=$2

scriptybase -t sqlite -d $DIR/test.db -r . -p $DIR --auto

cat <<-EOF
 See real file applied was

 $(md5sum t0007/patch1.sql.manual)

 If you find yourself in this situation, 
    locate the guilty and cut this hands
EOF


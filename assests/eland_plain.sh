#!/bin/sh

# POST_RUN=$1

# qmake -cwd -v PATH  -inherit -- all POST_RUN_COMMAND="$POST_RUN"
# qmake -cwd -v PATH  -inherit -- all
qmake -cwd -v PATH -- -j 24

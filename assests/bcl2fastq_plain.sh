#!/bin/sh

# ALIGNMENT_COMMAND=$1

# qmake -cwd -v PATH -inherit -- all POST_RUN_COMMAND="$ALIGNMENT_COMMAND"
# qmake -cwd -v PATH -inherit -- all
# qmake -cwd -v PATH -N bcl2fastq -- -j 32 POST_RUN_COMMAND="$ALIGNMENT_COMMAND"
# qmake -cwd -inherit -- all
qmake -cwd -v PATH -- -j 24

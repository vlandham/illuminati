#!/bin/sh
#$ -N make_bcl2fastq
#$ -S /bin/sh
#$ -o qmake.out
#$ -e qmake.err

ALIGNMENT_COMMAND=$1

qmake -cwd -v PATH -N bcl2fastq -inherit -- all POST_RUN_COMMAND="$ALIGNMENT_COMMAND"

#!/bin/sh
#$ -N make_eland
#$ -S /bin/sh
#$ -o align.out
#$ -e align.err

POST_RUN=$1

qmake -cwd -v PATH -N eland -inherit -- all POST_RUN_COMMAND="$POST_RUN"

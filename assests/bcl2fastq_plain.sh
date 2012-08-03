#!/bin/sh
#$ -S /bin/bash

SCRIPT="${1}"
shift

qmake -cwd -v PATH -- -j 24 POST_RUN_COMMAND="${SCRIPT}"

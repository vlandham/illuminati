#!/bin/bash -l
#$ -S /bin/bash

SCRIPT=$1
shift
# ALL=$*
ruby $SCRIPT "$@"

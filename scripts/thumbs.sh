#!/bin/bash

for i in $1/*
do
	j=`basename $i .png`
	k=`dirname $i`
	#echo "j is $j, k is $k"
	convert -contrast -thumbnail 110 "$i" $k/thumb.$j.png
done

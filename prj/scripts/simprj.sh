#!/bin/bash

#system workings
MINSOC_DIR=`pwd`/..

PROJECT=$1
OUTPUT=$2

if [ ! -f $PROJECT ]
then
    echo "Unexistent project file."
    exit 1
fi

if [ -z "$OUTPUT" ]
then
    echo "Second argument should be the destintion file for the file and directory inclusions."
    exit 1
fi

source $PROJECT

for dir in "${PROJECT_DIR[@]}"
do
    echo "+incdir+$MINSOC_DIR/$dir" >> $OUTPUT
done

for file in "${PROJECT_SRC[@]}"
do
    FOUND=0

    for dir in "${PROJECT_DIR[@]}"
    do
        if [ -f $MINSOC_DIR/$dir/$file ]
        then
            echo "$MINSOC_DIR/$dir/$file" >> $OUTPUT
            FOUND=1
        fi
    done

    if [ $FOUND != 1 ]
    then
        echo "FILE NOT FOUND"
        exit 1
    fi
done

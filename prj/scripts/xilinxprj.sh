#!/bin/bash

#system workings
MINSOC_DIR=`pwd`/..

PROJECT=$1
SRC_OUTPUT=$2
TOP_MODULE=$3

if [ ! -f $PROJECT ]
then
    echo "Unexistent project file."
    exit 1
fi

if [ -z "$SRC_OUTPUT" ]
then
    echo "Third argument should be the destintion file for the source inclusions."
    exit 1
fi
echo -n "" > $SRC_OUTPUT

source $PROJECT

for file in "${PROJECT_SRC[@]}"
do
    FOUND=0

    for dir in "${PROJECT_DIR[@]}"
    do
        if [ -f $MINSOC_DIR/$dir/$file ]
        then
            echo -n '`include "' >> $SRC_OUTPUT
            echo -n "$MINSOC_DIR/$dir/$file" >> $SRC_OUTPUT
            echo '"' >> $SRC_OUTPUT
            FOUND=1
            break
        fi
    done

    if [ $FOUND != 1 ]
    then
        echo "FILE NOT FOUND"
        exit 1
    fi
done

if [ -n "$TOP_MODULE" ]
then
    for file in src/blackboxes/*.v
    do
        echo -n '`include "' >> $SRC_OUTPUT
        echo -n "`pwd`/$file" >> $SRC_OUTPUT
        echo '"' >> $SRC_OUTPUT
    done
fi

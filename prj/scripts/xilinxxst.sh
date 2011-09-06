#!/bin/bash

#system workings
MINSOC_DIR=`pwd`/..

PROJECT=$1
DIR_OUTPUT=$2
PROJECT_FILE=$3
TOP_MODULE_NAME=$4
TOP_MODULE=$5

if [ ! -f $PROJECT ]
then
    echo "Unexistent project file."
    exit 1
fi

if [ -z "$DIR_OUTPUT" ]
then
    echo "Second argument should be the destintion file for the directory inclusions."
    exit 1
fi

source $PROJECT

echo "set -tmpdir "./xst"" >> $DIR_OUTPUT
echo "run" >> $DIR_OUTPUT

DIR_PATH="-vlgincdir {"

for dir in "${PROJECT_DIR[@]}"
do
    DIR_PATH="$DIR_PATH \"$MINSOC_DIR/$dir\" "
done

DIR_PATH="$DIR_PATH }"
echo $DIR_PATH >> $DIR_OUTPUT

echo "-ifn $MINSOC_DIR/prj/${PROJECT_FILE}" >> $DIR_OUTPUT
echo "-ifmt Verilog" >> $DIR_OUTPUT
echo "-ofn ${TOP_MODULE_NAME}" >> $DIR_OUTPUT
echo "-ofmt NGC" >> $DIR_OUTPUT
echo "-p DEVICE_PART" >> $DIR_OUTPUT
echo "-top ${TOP_MODULE_NAME}" >> $DIR_OUTPUT
echo "-opt_mode Speed" >> $DIR_OUTPUT
echo "-opt_level 1" >> $DIR_OUTPUT
if [ -n "$TOP_MODULE" ]
then
    echo "-iobuf yes" >> $DIR_OUTPUT
else
    echo "-iobuf no" >> $DIR_OUTPUT
fi

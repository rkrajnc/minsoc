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
echo -n "" > $OUTPUT

source $PROJECT

for dir in "${PROJECT_DIR[@]}"
do
    echo "set_global_assignment -name SEARCH_PATH $MINSOC_DIR/$dir" >> $OUTPUT
done

for file in "${PROJECT_SRC[@]}"
do
    FOUND=0

    for dir in "${PROJECT_DIR[@]}"
    do
        if [ -f $MINSOC_DIR/$dir/$file ]
        then
	    is_vhdl=`ls $MINSOC_DIR/$dir/$file | grep vhd`
	    if [ -z $is_vhdl ]
	    then
		echo "set_global_assignment -name VERILOG_FILE $MINSOC_DIR/$dir/$file" >> $OUTPUT
	    else
		echo "set_global_assignment -name VHDL_FILE $MINSOC_DIR/$dir/$file" >> $OUTPUT
	    fi
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

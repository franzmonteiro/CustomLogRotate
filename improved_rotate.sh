#!/bin/bash

DESTINATION_DIRECTORY=
while getopts d: opt
do
    case "$opt" in
        d)    DESTINATION_DIRECTORY="$OPTARG";;
        \?)   # unknown flag
              echo >&2 \
              "usage: $0 [-d directory] [file ...]"
              exit 1;;
    esac
done
shift `expr $OPTIND - 1`

LOG_FILES=$@
echo "DESTINATION_DIRECTORY = $DESTINATION_DIRECTORY"
echo "LOG_FILES = $LOG_FILES"
#exit 0

for LOG_FILE in $LOG_FILES
do
    COUNT=1
    # Infinite loop
    while :
    do
        # Define rotated file name.
        ROTATED_FILENAME=$LOG_FILE.gz.$COUNT
        if [ ! -f $ROTATED_FILENAME ]; then
            break
        fi
        $(( COUNT++ ))
    done
    gzip -9v $LOG_FILE > $ROTATED_FILENAME
    echo $LOG_FILE
done

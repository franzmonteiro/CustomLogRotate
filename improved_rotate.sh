#!/bin/bash
TODAY=$(date +%Y%m%d)
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

if [ -d DESTINATION_DIRECTORY ]; then
    echo "The following destination directory does not exist: '$DESTINATION_DIRECTORY'"
    echo "Execution aborted."
    exit 1
fi

LOG_FILES=$@
echo "DESTINATION_DIRECTORY = $DESTINATION_DIRECTORY"
echo "LOG_FILES = $LOG_FILES"

for LOG_FILE in $LOG_FILES
do
    if [ ! -f $LOG_FILE ]; then
        echo "'$LOG_FILE' does not exist."
    fi
    
    ROTATION_NUMBER=1
    # Infinite loop
    while :
    do
        # Define rotated filename.
        ROTATED_FILENAME="$LOG_FILE.$TODAY.$ROTATION_NUMBER"
        COMPLETE_DESTINATION="$DESTINATION_DIRECTORY/$ROTATED_FILENAME"
        COMPLETE_DESTINATION=$(echo $COMPLETE_DESTINATION | sed 's_//_/_')
        echo "COMPLETE_DESTINATION = $COMPLETE_DESTINATION"
        if [ ! -f $ROTATED_FILENAME ]; then
            break
        fi
        $(( ROTATION_NUMBER++ ))
    done
    gzip -9cv $LOG_FILE > $COMPLETE_DESTINATION
done

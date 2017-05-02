#!/bin/bash

MANUAL_ROTATIONS_DIR="/home/lmonteiro/Documents"
MANUAL_ROTATIONS_LOG="/manual_rotations.log"
TODAY=`date +%Y%m%d`
DESTINATION_DIRECTORY=""

function usage() {
    echo "usage: $0 [-d destination directory] [file ...]"
}

function log_message() {
    echo -e "[$(date '+%Y.%m.%d %H:%M:%S') $1] $2" | tee -a $MANUAL_ROTATIONS_LOG
}

function log_error() {
    log_message "ERROR" $1
}

function log_info() {
    log_message "INFO" $1
}

while getopts d: opt
do
    case "$opt" in
        d)    DESTINATION_DIRECTORY="$OPTARG";;
        \?)   # unknown flag
              echo >&2 \
              #TODO: Print usage.
              exit 1;;
    esac
done
shift `expr $OPTIND - 1`

# If the destination directory was defined by the user.
if [ -n "$DESTINATION_DIRECTORY" ]; then
    if ! [ -d "$DESTINATION_DIRECTORY" ]; then
        log_error "The following destination directory does not exist: $DESTINATION_DIRECTORY"
        log_error "Execution aborted."
        exit 1
    fi
    if ! [ -w "$DESTINATION_DIRECTORY" ]; then
        log_error "$USER does not have write permission on" \
                  "the following directory: $DESTINATION_DIRECTORY"
        log_error "Execution aborted."
        exit 1
    fi
fi

if [ "$#" -lt "1" ]; then
    usage #TODO: Correct it.
    exit 1
fi

#TODO: Test it.
if ! [ -d $MANUAL_ROTATIONS_DIR ]; then
    echo "$MANUAL_ROTATIONS_DIR does not exist. I will try to create it."
    mkdir -p $MANUAL_ROTATIONS_DIR
    if [ "$?" -ne "0" ]; then
        echo -e "It was not possible to create $MANUAL_ROTATIONS_DIR"
        echo "Execution aborted."
        exit 1
    fi
    echo "$MANUAL_ROTATIONS_DIR created!"
fi

if ! [ -f $MANUL_ROTATIONS_LOG ]; then
    echo "$MANUAL_ROTATIONS_LOG does not exist. I will try to create it."
    touch $MANUAL_ROTATIONS_LOG
    if [ "$?" -ne "0" ]; then
        echo "It was not possible to create $MANUAL_ROTATIONS_LOG"
        echo "Execution aborted."
        exit 1
    fi
    echo "$MANUAL_ROTATIONS_LOG created!"
fi

FILES=$@
for FILE in $FILES
do
    if ! [ -f "$FILE" ]; then
        log_error "$FILE does not exist."
        continue
    fi
    
    if [ $(basename "$FILE") = $(basename "$0") ]; then
        log_error "Forbidden action. I can not rotate myself."
    fi
    
    # Check if file type is text.
    file -b "$FILE" | grep "text" > /dev/null
    if [ "$?" -ne "0" ]; then
        log_error "$FILE's type is not text, or it is empty."
        continue
    fi
    
    if [ -x "$FILE" ]; then
        log_error "$FILE is an executable file."
        continue
    fi
    
    ROTATION_NUMBER=1
    log_info "Rotating file: $FILE"
    if [ -n "$DESTINATION_DIRECTORY" ]; then
        # Get filename. From something like '/home/user/file1.log', get 'file1.log'.
        CURRENT_FILENAME=`basename "$FILE"`
        NEW_FILE="$DESTINATION_DIRECTORY/$CURRENT_FILENAME"
        # Replaces eventual double slashes by a single slash.
        NEW_FILE=`echo "$NEW_FILE" | sed 's_//_/_'`
    else
        NEW_FILE="$FILE"
    fi
    NEW_FILE="$NEW_FILE.$TODAY"
    
    # Infinite loop
    while :
    do
        if ! [ -f "$NEW_FILE.$ROTATION_NUMBER" ] && \
            ! [ -f "$NEW_FILE.$ROTATION_NUMBER.gz" ]; then
            break
        fi
        ROTATION_NUMBER=$(( ROTATION_NUMBER + 1 ))
    done
    NEW_FILE="$NEW_FILE.$ROTATION_NUMBER"
    
    log_info "Creating file: $NEW_FILE"
    cp "$FILE" "$NEW_FILE"
    if [ "$?" -ne "0" ]; then
        log_error "An error occurred while creating $NEW_FILE"
    fi
    log_info "File created successfully!"
    
    log_info "Truncating file: $FILE"
    cat /dev/null > "$FILE"
    if [ "$?" -ne "0" ]; then
        log_error "An error occurred while truncating $FILE"
    fi
    log_info "File truncated successfully!"
    
    log_info "Compressing file: $NEW_FILE"
    gzip -9v "$NEW_FILE"
    if [ "$?" -ne "0" ]; then
        log_error "An error occurred while compressing $NEW_FILE"
    fi
done
log_info "Execution finished."
#TODO: Print statistics.

#!/bin/bash

. utils.sh      # Necessary for log function

set -e

# Initialize log file
init_log "$0"

# Input errors checking
if [[ $# -eq 0 ]]; then
    log "There is should be at least one argument passed"
    exit 1
elif [[ -z "${1// }" ]]; then
    log "There is should be nonempty backup target filename specified"
    exit 1
fi

# Target to backup
TARGET=$1
# incron action
ACTION=$2
# Name for target's metadata file
METADATA_NAME=$3

if [[ ! -e $TARGET ]]; then
    log "File or directory not exists: $TARGET"
    exit 1
fi

# Root directory for backups
BACKUP_DIR=$HOME/Workspace/Project/gnulinux-post-install/gnulinux-backup/files
# Location of target file in system's rootfs
SOURCE_DIR=$(dirname "$TARGET")
# Target filename
TARGET_NAME=$(basename "$TARGET")
# Directory where backup will be placed
DEST_DIR="$BACKUP_DIR$SOURCE_DIR"

# Get the owner of the file 
FILE_OWNER=$(stat -c %U "$TARGET")
# Get the owner of the parent directory
DIR_OWNER=$(stat -c %U "$SOURCE_DIR")

log "source file: $TARGET"
log "event: $ACTION"
log "destination file: $DEST_DIR/$TARGET_NAME"

if [[ $ACTION == "IN_DELETE" || $ACTION == "IN_DELETE,IN_ISDIR" ]]; then
    rm -r "$BACKUP_DIR$TARGET"
    /home/serhiy/.bin/backup-metadata.sh "$TARGET" $ACTION "$METADATA_NAME"
elif [[ $ACTION == "IN_ATTRIB" || $ACTION == "IN_ATTRIB,IN_ISDIR" ]]; then
    /home/serhiy/.bin/backup-metadata.sh "$TARGET" $ACTION "$METADATA_NAME"
else
    mkdir -p "$DEST_DIR"

    if [[ $FILE_OWNER == "root" || $DIR_OWNER == "root" ]]; then
        sudo cp -r "$TARGET" "$DEST_DIR"
    else
        cp -r "$TARGET" "$DEST_DIR"
    fi

    /home/serhiy/.bin/backup-metadata.sh "$TARGET" $ACTION "$METADATA_NAME"
    if [[ $ACTION == "IN_IGNORED" ]]; then
        sudo service incron restart
    fi
fi

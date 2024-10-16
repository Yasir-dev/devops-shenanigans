#!/bin/bash


# Check if the number of arguments is not equal to 1
if [[ $# -ne 1 ]]; then
    # Print the usage message: $0 is the script name
    echo "Usage: $0 <log-directory-path>"
    # Exit with status 1 (error)
    exit 1
fi

LOGS_DIR=$1

# -d option is used to check if the directory exists
# double qoutes are used to handle spaces and special characters as a single argument
if [[ ! -d "$LOGS_DIR" ]]; then
    echo "The specified directory: $LOGS_DIR does not exist!"
    exit 1
fi

# -r option is used to check if the directory is readable by the user
if [[ ! -r "$LOGS_DIR" ]]; then
    echo "The specified directory: $LOGS_DIR is not readable! by the user"
    exit 1
fi

# create a variable to read date in this format: 20240716
CURRENT_DATE=$(date +%Y%m%d)

# create a variable to read the time in this format: 100648
CURRENT_TIME=$(date +%H%M%S)

LOG_ARCHIVE_FILE="$LOGS_DIR/archive_$CURRENT_DATE_$CURRENT_TIME.tar.gz"

#-c: Create a new archive.
#-z: Compress the archive using gzip.
#-v: Verbose mode; display the progress of the archiving process, showing the files being processed.
#-f: Specify the filename of the archive.
tar -czvf "$LOG_ARCHIVE_FILE" "$LOGS_DIR"

echo "Logs archived successfully to $LOG_ARCHIVE_FILE"
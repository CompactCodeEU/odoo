#!/bin/bash
set -e

# Ensure parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <old_source> <new_folder>"
    exit 1
fi

# Get absolute paths of arguments
OLD_SOURCE=$(realpath "$1")
NEW_FOLDER=$(realpath "$2")

# Ensure NEW_FOLDER exists
if [ ! -d "$NEW_FOLDER" ]; then
    echo "Error: Destination folder '$NEW_FOLDER' does not exist."
    exit 1
fi

# Check if OLD_SOURCE is a .tar.gz file
if [[ "$OLD_SOURCE" == *.tar.gz ]]; then
    EXTRACTED_OLD_DIR=$(dirname "$OLD_SOURCE")/extracted_old

    # Remove any previous extraction and create a fresh directory
    rm -rf "$EXTRACTED_OLD_DIR"
    mkdir -p "$EXTRACTED_OLD_DIR"

    echo "Extracting $OLD_SOURCE to $EXTRACTED_OLD_DIR..."
    tar -xzf "$OLD_SOURCE" -C "$EXTRACTED_OLD_DIR"

    # Check for a single top-level directory in the extracted content
    extracted_content=("$EXTRACTED_OLD_DIR"/*)
    if [[ ${#extracted_content[@]} -eq 1 ]] && [[ -d "${extracted_content[0]}" ]]; then
        OLD_FOLDER="${extracted_content[0]}"  # Use the extracted folder if there's only one
    else
        OLD_FOLDER="$EXTRACTED_OLD_DIR"
    fi
else
    OLD_FOLDER="$OLD_SOURCE"
fi

# Ensure OLD_FOLDER exists
if [ ! -d "$OLD_FOLDER" ]; then
    echo "Error: Source folder '$OLD_FOLDER' does not exist."
    exit 1
fi

# Iterate through folders in OLD_FOLDER
for folder in "$OLD_FOLDER"/*; do
    if [ -d "$folder" ]; then
        folder_name=$(basename "$folder")
        target_folder="$NEW_FOLDER/$folder_name"

        # If the folder does not exist in NEW_FOLDER, copy it entirely
        if [ ! -d "$target_folder" ]; then
            echo "Copying entire folder: $folder_name"
            cp -r "$folder" "$NEW_FOLDER/"
        else
            # If the folder exists, copy files without overwriting or deleting existing files
            echo "Merging files into existing folder: $folder_name"
            cp -rn "$folder/"* "$target_folder/"
        fi
    fi
done

# Clean up the extracted directory if it was used
if [[ "$OLD_SOURCE" == *.tar.gz ]]; then
    echo "Cleaning up temporary folder: $EXTRACTED_OLD_DIR"
    rm -rf "$EXTRACTED_OLD_DIR"
fi

echo "Syncing complete!"

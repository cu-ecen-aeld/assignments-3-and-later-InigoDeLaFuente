#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <writefile> <writestr>"
    exit 1
fi

# Extract arguments
writefile="$1"
writestr="$2"

# Create the directory path if it doesn't exist
mkdir -p "$(dirname "$writefile")"

# Write the content to the file
echo -n "$writestr" > "$writefile"

# Check if the file was successfully created
if [ $? -ne 0 ]; then
    echo "Error: Failed to create the file '$writefile'."
    exit 1
fi

echo "File '$writefile' created successfully with content: '$writestr'."


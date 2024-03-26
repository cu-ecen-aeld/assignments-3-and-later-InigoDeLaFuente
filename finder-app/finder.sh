#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <filesdir> <searchstr>"
    exit 1
fi

# Extract arguments
filesdir="$1"
searchstr="$2"

# Check if filesdir exists and is a directory
if [ ! -d "$filesdir" ]; then
    echo "Error: '$filesdir' is not a directory or does not exist."
    exit 1
fi

# Count the number of files and matching lines
number_of_files=$(find "$filesdir" -type f | wc -l)
number_of_matches=$(grep -r "$searchstr" "$filesdir" | wc -l)

# Print the results
echo "The number of files are $number_of_files and the number of matching lines are $number_of_matches."

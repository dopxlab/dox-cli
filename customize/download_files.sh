#!/bin/bash

function download_tool_to_configure() {
    
    local path="$1"       # URL to the dependency
    local temp_file="$2"  # File path to save the downloaded file

    # Download the file using curl
    echo "Downloading from: $path"
    curl -sL "$path" -o "$temp_file"

    # Check if the download was successful
    if [ $? -ne 0 ]; then
        echo "Error: Download failed from $path"
        return 1
    fi

    echo "Downloaded successfully to $temp_file"
    return 0
}

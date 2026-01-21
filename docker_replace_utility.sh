#!/bin/bash

set -e  # Exit on error
function replace_variables(){
    input_file=$1
    temp_file=$(mktemp)
    sed \
    -e "s|##FROM_IMAGE##|jre|g" \
    $input_file > $temp_file
    mv $temp_file $input_file
}

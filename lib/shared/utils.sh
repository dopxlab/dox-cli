#!/bin/bash

# Function to escape slashes in a string
function escape_slashes() {
    local input_string="$1"
    local escaped_string=$(echo "$input_string" | sed 's/\//\\\//g')
    echo "$escaped_string"
}

function get_workspace_path() {
    local workspace="$GITHUB_WORKSPACE"
    if [ -n "$BUILD_PATH" ]; then
        workspace="$GITHUB_WORKSPACE/$BUILD_PATH"
    fi   
    echo "$workspace"
}

function cd_workspace() {
    local workspace
    workspace=$(get_workspace_path)
    echo "Workspace: $workspace"
    # Change to the workspace directory
    cd "$workspace" || { echo "Failed to change directory to $workspace"; exit 1; }
}

function get_artifacts_path(){
    local artifacts_path=$ARTIFACTS_PATH
    if [ -v BUILD_PATH ]; then
        artifacts_path="$ARTIFACTS_PATH/$BUILD_PATH"
    fi
    echo "$artifacts_path"
}

function validate_variable() {
    local var_name="$1"
    local var_value="${!var_name}"  # Get the value of the variable using indirect reference

    if [ -z "$var_value" ]; then
        error "ERROR: ${var_name} is not defined or empty. Please provide a value for ${var_name}."
        exit 1
    else
        print "36" "${var_name}: ${var_value}"
    fi
}
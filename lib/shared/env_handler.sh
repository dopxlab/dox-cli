#!/usr/bin/env bash

# Define the environment file where environment variables will be stored
DOX_ENV="dox_env"  # This is the environment file
BEFORE_FILE="env_before.txt"
AFTER_FILE="env_after.txt"

# Export DOX_ENV variable (this will be part of the environment)
export DOX_ENV="dox_env"
echo "Exported DOX_ENV=$DOX_ENV"
cat $DOX_ENV
echo "----"

# Function to capture environment variables and save them to a file
capture_env() {
    local env_file="$1"
    env > "$env_file"
}

# Function to extract newly added environment variables from the diff
extract_added_vars() {
    local before="$1"
    local after="$2"
    
    # Use diff and grep to capture only the added environment variables
    diff "$before" "$after" | grep "^>" | sed 's/^> //' >> "$DOX_ENV"
}

# Step 1: Before execution
function on_before_execution() {
    # Capture the environment before running the DOX command
    capture_env "$BEFORE_FILE"
}

# Step 2: After execution
function on_after_execution() {
    # Capture the environment after running the DOX command
    capture_env "$AFTER_FILE"

    # Find the newly added environment variables and append them to DOX_ENV
    extract_added_vars "$BEFORE_FILE" "$AFTER_FILE"

    # Clean up temporary files
    rm -f "$BEFORE_FILE" "$AFTER_FILE"
}

# Main execution flow
#on_before_execution

# Example of setting a new environment variable
#export NAME="DOX-CLI"
#export NAME1="DOX-CLI1"
#export NAME2="DOX-CLI2"

# Step 2: After execution
#on_after_execution

#echo "Diffing and saving environment changes complete."

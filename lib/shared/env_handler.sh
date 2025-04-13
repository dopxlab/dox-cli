#!/usr/bin/env bash

# Define the environment file where environment variables will be stored
DOX_ENV="dox_env"  # This is the environment file
BEFORE_FILE="env_before.txt"
AFTER_FILE="env_after.txt"

# Export DOX_ENV variable (this will be part of the environment)
export DOX_ENV="dox_env"
echo "Exported DOX_ENV=$DOX_ENV"
cat "$DOX_ENV"
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

# Function to remove duplicates and update the DOX_ENV file with the latest values
update_env_file() {
    # Create a temporary file to store the updated environment variables
    local temp_env_file=$(mktemp)

    # Iterate through the DOX_ENV file and update or append the variables
    while IFS='=' read -r key value; do
        # If the key is already in the current environment, use the latest value
        eval "current_value=\$$key"
        
        if [[ -n "$current_value" ]]; then
            # Update the variable with the latest value
            echo "$key=$current_value" >> "$temp_env_file"
        else
            # If the variable doesn't exist, append it with the last known value from DOX_ENV
            echo "$key=$value" >> "$temp_env_file"
        fi
    done < "$DOX_ENV"

    # Sort and remove duplicate entries
    sort "$temp_env_file" | uniq > "$DOX_ENV"

    # Clean up the temporary file
    rm -f "$temp_env_file"
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

    # Update DOX_ENV to remove duplicates and use the latest values
    update_env_file

    # Clean up temporary files
    rm -f "$BEFORE_FILE" "$AFTER_FILE"
}


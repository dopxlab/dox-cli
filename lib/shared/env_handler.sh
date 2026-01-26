#!/usr/bin/env bash

# ✅ CHANGE: DOX_ENV is now in current directory
DOX_ENV="${DOX_ENV:-${PWD}/dox_env}"

# Use current directory for temporary files
DOX_ENV_DIR="$(dirname "$DOX_ENV")"
BEFORE_FILE="${DOX_ENV_DIR}/.env_before.txt"
AFTER_FILE="${DOX_ENV_DIR}/.env_after.txt"

# Function to capture environment variables and save them to a file
capture_env() {
    local env_file="$1"
    env > "$env_file"
}

# ✅ UPDATE: extract_added_vars function
extract_added_vars() {
    local before="$1"
    local after="$2"
    
    # Create header if file doesn't exist
    if [ ! -f "$DOX_ENV" ]; then
        echo "#!/bin/bash" > "$DOX_ENV"
        echo "# DOX Environment Variables" >> "$DOX_ENV"
        echo "# Source this file: source ./dox_env" >> "$DOX_ENV"
        echo "" >> "$DOX_ENV"
    fi
    
    # Add new variables with export
    diff "$before" "$after" | grep "^>" | sed 's/^> /export /' >> "$DOX_ENV"
}

# ✅ UPDATE: update_env_file function
update_env_file() {
    local temp_env_file=$(mktemp)

    # Preserve header
    if [ -f "$DOX_ENV" ]; then
        head -4 "$DOX_ENV" > "$temp_env_file"
    fi

    # Process variables
    while IFS='=' read -r key value; do
        # Skip header lines
        [[ "$key" =~ ^# ]] && continue
        [[ "$key" =~ ^#!/ ]] && continue
        
        # Strip 'export ' prefix if present
        key="${key#export }"
        key="${key## }"  # Trim leading spaces
        
        # Skip empty keys
        [ -z "$key" ] && continue
        
        # Get current value
        eval "current_value=\$$key"

        if [[ -n "$current_value" ]]; then
            # Quote non-numeric values
            if [[ ! "$current_value" =~ ^-?[0-9]+(\.[0-9]+)?$ && ! "$current_value" =~ ^\".*\"$ ]]; then
                current_value="\"$current_value\""
            fi
            echo "export $key=$current_value" >> "$temp_env_file"
        else
            # Use last known value
            if [[ ! "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ && ! "$value" =~ ^\".*\"$ ]]; then
                value="\"$value\""
            fi
            echo "export $key=$value" >> "$temp_env_file"
        fi
    done < <(grep "^export" "$DOX_ENV" 2>/dev/null)

    # Sort and remove duplicates (keep header at top)
    (head -4 "$temp_env_file"; tail -n +5 "$temp_env_file" | sort | uniq) > "$DOX_ENV"

    rm -f "$temp_env_file"
    chmod +x "$DOX_ENV"
}

# Step 1: Before execution
function on_before_execution() {
    # Capture the environment before running the DOX command
    if [[ -f "$DOX_ENV" ]]; then
        source "$DOX_ENV"
    fi
    capture_env "$BEFORE_FILE"
}

# Step 2: After execution
function on_after_execution() {
    # Check if the BEFORE_FILE exists
    [[ ! -f "$BEFORE_FILE" ]] && return

    # Capture the environment after running the DOX command
    capture_env "$AFTER_FILE"

    # Find the newly added environment variables and append them to DOX_ENV
    extract_added_vars "$BEFORE_FILE" "$AFTER_FILE"

    # Update DOX_ENV to remove duplicates and use the latest values
    update_env_file

    # Clean up temporary files
    rm -f "$BEFORE_FILE" "$AFTER_FILE"
}



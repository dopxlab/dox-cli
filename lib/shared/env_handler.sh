#!/usr/bin/env bash

# Define the environment file where environment variables will be stored
DOX_ENV="dox_env"  # This is the environment file
BEFORE_FILE="env_before.txt"
AFTER_FILE="env_after.txt"

# Export DOX_ENV variable (this will be part of the environment)
export DOX_ENV="dox_env"
#echo "Exported DOX_ENV=$DOX_ENV"
#cat "$DOX_ENV"
#echo "----"

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
    local temp_env_file=$(mktemp)

    while IFS= read -r line; do
        # Skip empty lines or lines without export
        [[ -z "$line" || ! "$line" =~ ^export\  ]] && continue

        # Remove 'export ' prefix and split into key=value
        local line_no_export="${line#export }"
        local key="${line_no_export%%=*}"
        local value="${line_no_export#*=}"

        # Evaluate latest value from the environment
        eval "current_value=\$$key"

        if [[ -n "$current_value" ]]; then
            # Quote current_value if not numeric or already quoted
            if [[ ! "$current_value" =~ ^-?[0-9]+(\.[0-9]+)?$ && ! "$current_value" =~ ^\".*\"$ ]]; then
                current_value="\"$current_value\""
            fi
            echo "export $key=$current_value" >> "$temp_env_file"
        else
            # Quote value from file if necessary
            if [[ ! "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ && ! "$value" =~ ^\".*\"$ ]]; then
                value="\"$value\""
            fi
            echo "export $key=$value" >> "$temp_env_file"
        fi
    done < "$DOX_ENV"

    # Sort and deduplicate by key (latest takes precedence)
    tac "$temp_env_file" | awk '!seen[$2]++' | tac > "$DOX_ENV"

    rm -f "$temp_env_file"
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

function update_dox_env() {
  local key="$1"
  local value="$2"
  local file="${DOX_ENV}"  # Defaults to DOX_ENV if no file passed

  # Create file if it doesn't exist
  [ -f "$file" ] || touch "$file"

  # Remove existing key (if exists)
  grep -v "^export $key=" "$file" > "${file}.tmp"
  
  # Add updated key=value
  echo "export $key=\"$value\"" >> "${file}.tmp"

  # Replace original file
  mv "${file}.tmp" "$file"
}

#!/usr/bin/env bash

# Enable case-insensitive matching for the script
shopt -s nocasematch


# Function to escape slashes in a string
function escape_slashes() {
    local input_string="$1"
    local escaped_string=$(echo "$input_string" | sed 's/\//\\\//g')
    echo "$escaped_string"
}

# Function to evaluate and export variables from YAML
function generate_utility_script() {
    CONFIG_FILE="$1"
    echo "Extracting variables from $CONFIG_FILE..."
    # Declare an associative array to store variables
    SED_UTILITY="$2"
    echo "#!/bin/bash" >"$SED_UTILITY"
    echo "" >> "$SED_UTILITY"
    echo "set -e  # Exit on error" >> "$SED_UTILITY"
    echo "function replace_variables(){" >> "$SED_UTILITY"
    echo "    input_file=\$1" >> "$SED_UTILITY"
    echo "    temp_file=$(mktemp)" >> "$SED_UTILITY"
    echo "    sed \\" >> "$SED_UTILITY"
    # Extract YAML key-value pairs
    yq eval '.variables | to_entries | .[] | "\(.key)=\(.value)"' "$CONFIG_FILE" | while read -r line; do
        # Handle command substitution
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)

        value=$(escape_slashes "$value")

        # Evaluate and export the key-value pair
        eval "export $key=\"$value\""
        # Echo the evaluated value
        #eval "echo export $key=\$$key"

        echo "    -e \"s|##$key##|${!key}|g\" \\" >> "$SED_UTILITY"

    done
    echo "    \$input_file > \$temp_file" >> "$SED_UTILITY"
    echo "    mv \$temp_file \$input_file" >> "$SED_UTILITY"

    echo "}" >> "$SED_UTILITY"

    #cat $VARIABLES_FILE
}

function run_replace_variables(){
    FILES_DIR=$1
    REPLACE_UTILITY="replace_utility.sh"
    generate_utility_script "../custom/build/helm.yaml" $REPLACE_UTILITY

    source $REPLACE_UTILITY
    cat $REPLACE_UTILITY

    find "$FILES_DIR" -type f | while read -r file; do
        echo "Processing: $file"
        replace_variables $file
    done
}
function run_configure(){
    echo ""
}

# Function to run a specific action
function run_action() {
  local tool_name=$1
  local action=$2
  echo "⚙️ Executing action: $action using tool: $tool_name"

  # Define source and temp directories
  TEMPLATE_FOLDER="${DOX_CUSTOM_DIR}/action/templates/$tool_name"
  TEMP_FOLDER="../deleteme"  # Unique temp folder
  rm -rf $TEMP_FOLDER

  cp -r "$TEMPLATE_FOLDER" "$TEMP_FOLDER"
  echo "Templates copied to: $TEMP_FOLDER"

  run_configure
  run_replace_variables $TEMP_FOLDER
  run_action
}

function create_template(){
  local tool_name=$1
  mktemp -d helm-XXXXXX

}

echo "🚀 Running action for tool: $1"

# Loop through the actions (starting from $2 as the first argument is the tool name)
for action in "${@:2}"; do
    run_action "$1" "$action"
done

echo "✅ Actions completed for tool: $1"
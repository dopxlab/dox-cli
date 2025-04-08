#!/usr/bin/env bash

# Enable case-insensitive matching for the script
shopt -s nocasematch

source ${DOX_DIR}/lib/shared/print.sh

#Optional: As its already configured in dox
export DOX_DIR="${DOX_DIR:-$HOME/.dox}"
export DOX_CUSTOM_DIR="${DOX_CUSTOM_DIR:-$DOX_DIR/customize}"

# action yaml location
ACTION_FILE_PATH="${DOX_CUSTOM_DIR}/action"

# Function to ensure a file exists, exit if not
function ensure_file_exists() {
    [ -f "$1" ] || { echo "Error: File $1 not found!" >&2; exit 1; }
}

# Function to get a value from a YAML file by key
function get_yaml_value() {
    ensure_file_exists "$1"
    yq eval -r "$2" "$1"
}

# Function to escape slashes in a string
function escape_slashes() {
    local input_string="$1"
    local escaped_string=$(echo "$input_string" | sed 's/\//\\\//g')
    echo "$escaped_string"
}

# Function to evaluate and export variables from YAML
function generate_utility_script() {
    config_file="$1"
    echo "📄 Extracting variables from $config_file... and generating utility script 🛠️"
    # Declare an associative array to store variables
    sed_utility_script="$2"
    echo "#!/bin/bash" >"$sed_utility_script"
    echo "" >> "$sed_utility_script"
    echo "set -e  # Exit on error" >> "$sed_utility_script"
    echo "function replace_variables(){" >> "$sed_utility_script"
    echo "    input_file=\$1" >> "$sed_utility_script"
    echo "    temp_file=$(mktemp)" >> "$sed_utility_script"
    echo "    sed \\" >> "$sed_utility_script"
    # Extract YAML key-value pairs
    yq eval '.variables | to_entries | .[] | "\(.key)=\(.value)"' "$config_file" | while read -r line; do
        # Handle command substitution
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)

        value=$(escape_slashes "$value")

        # Evaluate and export the key-value pair
        eval "export $key=\"$value\""
        # Echo the evaluated value
        #eval "echo export $key=\$$key"

        echo "    -e \"s|##$key##|${!key}|g\" \\" >> "$sed_utility_script"

    done
    echo "    \$input_file > \$temp_file" >> "$sed_utility_script"
    echo "    mv \$temp_file \$input_file" >> "$sed_utility_script"
    echo "}" >> "$sed_utility_script"
}

function run_replace_variables(){
    local lib=$1
    local template_dir=$2

    replace_utility_script="${lib}_replace_utility.sh"
    generate_utility_script "$ACTION_FILE_PATH/$lib.yaml" $replace_utility_script

    source $replace_utility_script
    cat $replace_utility_script

    find "$template_dir" -type f | while read -r file; do
        echo "Processing: $file"
        replace_variables $file #Calling dynamically generatoed method on runtime
    done
}

function run_action_script(){
    local lib=$1
    local script_path=$2
    local lib_config_file="$ACTION_FILE_PATH/$lib.yaml"

    # Extract the script value using yq
    script=$(yq eval "${script_path} // \"\"" "$lib_config_file")

    # Check if the script is empty, if it's not, then run it
    if [[ -n "$script" ]]; then
        print "33" "40" "Running $script_path Script"  # Yellow text on black background
        echo ""
        echo -e "\033[0;32m$script\033[0m"
        echo ""

        eval "$script"
    else
        info "No script found $lib_config_file in $script_path for $lib. Skipping script execution."
    fi
}

# Function to run a specific action
function configure_action() {
  local lib=$1
  echo "🛠️ Configuring Tool: $lib"

  #Step 1: Configuration Run Configure script
  run_action_script $lib ".configure"

  #Step 2: Process Template # Reference template folder based on lib
  local ref_template_folder=$(yq eval ".template_folder // \"\"" "$ACTION_FILE_PATH/$lib.yaml")
  ref_template_folder=$(eval echo "$ref_template_folder")
  
    if [ -d "$ref_template_folder" ]; then
        echo "Template: $ref_template_folder exists"
        # Create a real temporary folder and export the path as an environment variable
        
        # Creates a unique temporary directory and copy the files to template_folder
        export template_folder=$(mktemp -d)  
        echo "Temporary folder created at: $template_folder"
        
        cp -r "$ref_template_folder" "$template_folder"
        echo "Templates copied to: $template_folder"

        #Generate SED Command
        run_replace_variables $lib $template_folder
    fi
}

lib=$1
echo "🚀 Running action for tool: $lib"
ensure_file_exists "$ACTION_FILE_PATH/$lib.yaml"
configure_action $lib

# Loop through the actions (starting from $2 as the first argument is the tool name)
for action in "${@:2}"; do
    echo "⚙️ Executing action: '$lib $action'"
    run_action_script $lib ".actions.$action"
    
done

echo "✅ Actions completed for tool: $lib"
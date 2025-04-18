#!/usr/bin/env bash

# Enable case-insensitive matching
shopt -s nocasematch

source "${DOX_DIR}/lib/shared/print.sh"

# Optional defaults
export DOX_DIR="${DOX_DIR:-$HOME/.dox}"
export DOX_CUSTOM_DIR="${DOX_CUSTOM_DIR:-$DOX_DIR/customize}"
export DOX_ENV="dox_env"

# Action YAML location
ACTION_FILE_PATH="${DOX_CUSTOM_DIR}/action"

# Ensure file exists or exit
function ensure_file_exists() {
    [ -f "$1" ] || { echo "Error: File $1 not found!" >&2; exit 1; }
}

# Get YAML value by key using yq
function get_yaml_value() {
    ensure_file_exists "$1"
    yq eval -r "$2" "$1"
}

# Escape slashes for sed compatibility
function escape_slashes() {
    local input_string="$1"
    local escaped_string
    escaped_string=$(echo "$input_string" | sed 's/\//\\\//g')
    echo "$escaped_string"
}

# Generate dynamic sed utility script for variable replacement
function generate_utility_script() {
    local config_file="$1"
    local sed_utility_script="$2"

    if [[ -f "$DOX_ENV" ]]; then
        debug "DOX Env Variables: "
        debug "$(cat "$DOX_ENV")"
        source "$DOX_ENV"
    fi

    echo "📄 Extracting variables from $config_file... and generating utility script 🛠️"

    echo "#!/bin/bash" > "$sed_utility_script"
    echo "" >> "$sed_utility_script"
    echo "set -e  # Exit on error" >> "$sed_utility_script"
    echo "function replace_variables(){" >> "$sed_utility_script"
    echo "    input_file=\$1" >> "$sed_utility_script"
    echo "    temp_file=\$(mktemp)" >> "$sed_utility_script"
    echo "    sed \\" >> "$sed_utility_script"

    yq eval '.template.variables | to_entries | .[] | "\(.key)=\(.value)"' "$config_file" | while read -r line; do
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)
        value=$(escape_slashes "$value")
        eval "export $key=\"$value\""
        echo "    -e \"s|##$key##|${!key}|g\" \\" >> "$sed_utility_script"
    done

    echo "    \$input_file > \$temp_file" >> "$sed_utility_script"
    echo "    mv \$temp_file \$input_file" >> "$sed_utility_script"
    echo "}" >> "$sed_utility_script"
}

# Replaces variables in template files
function run_replace_variables(){
    local lib=$1
    local template_dir=$2

    local replace_utility_script="${lib}_replace_utility.sh"
    generate_utility_script "$ACTION_FILE_PATH/$lib.yaml" "$replace_utility_script"

    source "$replace_utility_script"
    debug "$(cat "$replace_utility_script")"

    # ✅ FIXED: Avoid subshell using process substitution
    while IFS= read -r file; do
        echo "Processing: $file"
        replace_variables "$file"
    done < <(find "$template_dir" -type f)
}

# Run a script section from YAML
function run_action_script() {
    local lib=$1
    local script_path=$2
    local lib_config_file="$ACTION_FILE_PATH/$lib.yaml"

    local script
    script=$(yq eval "${script_path} // \"\"" "$lib_config_file")

    if [[ -n "$script" ]]; then
        print "34" "40" "🚀[$lib] Running $script_path script"

        local temp_script_file
        temp_script_file=$(mktemp /tmp/temp_script.XXXXXX)
        echo "$script" > "$temp_script_file"
        chmod +x "$temp_script_file"
        source "$temp_script_file"
        rm -f "$temp_script_file"
    else
        debug "No script found in $lib_config_file at $script_path. Skipping."
    fi
}

# Configure tool, replace template variables
function configure_action() {
    local lib=$1
    run_action_script "$lib" ".configure"

    local ref_template_folder
    ref_template_folder=$(yq eval ".template.folder // \"\"" "$ACTION_FILE_PATH/$lib.yaml")
    ref_template_folder=$(eval echo "$ref_template_folder")

    if [[ -d "$ref_template_folder" ]]; then
        echo "Template: $ref_template_folder exists"
        export template_folder=$(mktemp -d)
        echo "Temporary folder created at: $template_folder"

        cp -r "$ref_template_folder/." "$template_folder"
        echo "Templates copied to: $template_folder"

        run_replace_variables "$lib" "$template_folder"
    fi
}

# Entry point
lib=$1
ensure_file_exists "$ACTION_FILE_PATH/$lib.yaml"
configure_action "$lib"

# Run additional actions passed as arguments
for action in "${@:2}"; do
    run_action_script "$lib" ".actions.$action"
done

echo "✅ Actions completed for tool: $lib with actions: ${*:2}"

#!/bin/bash

#Optional: As its already configured in dox
export DOX_DIR="${DOX_DIR:-$HOME/.dox}"
export DOX_CUSTOM_DIR="${DOX_CUSTOM_DIR:-$DOX_DIR/customize}"
export DOX_RESOURCES_DIR="${DOX_RESOURCES_DIR:-$HOME/dox_resources}"
export DOX_USER_BIN="${DOX_USER_BIN:-${DOX_DIR}/bin}"
export DOX_ENV="dox_env"

source ${DOX_DIR}/lib/shared/env_handler.sh
source ${DOX_DIR}/lib/shared/print.sh
source ${DOX_DIR}/lib/shared/url_resolver.sh
source ${DOX_DIR}/lib/shared/version_handler.sh
source ${DOX_CUSTOM_DIR}/download_files.sh

# configuration yaml location
CONFIGURE_FILE_PATH="${DOX_CUSTOM_DIR}/configure"

print_envs DOX_CLI_VERSION DOX_DIR DOX_CUSTOM_DIR DOX_RESOURCES_DIR  

function get_arch_description() {
    case "$1" in
        x86_64) echo "Intel/AMD 64-bit (Ubuntu, macOS, Windows)" ;;
        armv7l) echo "ARM 32-bit (Raspberry Pi 2, older Android)" ;;
        aarch64) echo "ARM 64-bit (Raspberry Pi 3/4, Apple M1, ARM Servers)" ;;
        ppc64le) echo "PowerPC 64-bit (IBM Power Systems)" ;;
        *) echo "Unknown architecture" ;;
    esac
}

function configure_env_variables() {
    local lib=$1
    local version=$2
    local install_dir=$3

    # Check if the 'envs' section exists in the YAML for this library
    local envs=$(yq eval ".configuration.environments // []" "$CONFIGURE_FILE_PATH/$lib.yaml")

    # If 'envs' exists, process and set the environment variables
    if [ "$envs" != "[]" ]; then
        echo "$envs" | yq eval '. | to_entries | .[] | "\(.key)=\(.value)"' - | while IFS="=" read -r key value; do
            local evaluated_value=$(eval echo "$value")
            if [ "$key" == "PATH" ]; then
                create_symlinks_to_bin "$evaluated_value"
            else
                update_dox_env $key $evaluated_value
            fi
        done
    fi
    
    # Source environment for post_installation_scripts
    if [[ -f "$DOX_ENV" ]]; then
        source "$DOX_ENV"
    fi
}

function create_symlinks_to_bin() {
    local source_folder="$1"
    local bin_folder="${DOX_USER_BIN}"

    info "✓ Creating System Links from : $source_folder to bin: $bin_folder" >&2

    if [ ! -d "$source_folder" ]; then
        error "Source folder '$source_folder' does not exist."
        return 1
    fi

    # Ensure bin folder exists
    if [ ! -d "$bin_folder" ]; then
        mkdir -p "$bin_folder" || {
            error "Failed to create bin folder: $bin_folder"
            exit 1
        }
    fi

    for file in "$source_folder"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            
            # Skip non-executable or irrelevant files
            case "$filename" in
                *.txt|*.md|README|LICENSE) continue ;;
            esac

            if [[ -x "$file" ]]; then
                ln -sf "$file" "$bin_folder/$filename"
                info "✓ Linked $filename"
            fi
        fi
    done
}

function download_and_extract() {
    local lib_url=$1
    local install_dir=$2
    local temp_file=$(mktemp)
    local filename=$(basename "$lib_url")

    # Create target directory
    mkdir -p "$install_dir"

    # Download the file
    info "⬇ Downloading $filename..."
    download_tool_to_configure "$lib_url" "$temp_file"

    # Get the extension
    local extension="${filename##*.}"

    # Check if the file has an extension
    if [[ "$filename" == "$extension" ]]; then
        # No extension, assume it's a regular file and copy
        mv "$temp_file" "$install_dir/$filename"
        info "✓ Download complete"
    else
        # File has an extension, extract accordingly
        case "$extension" in
            gz|tgz)
                tar -xzf "$temp_file" -C "$install_dir" 2>/dev/null
                ;;
            zip)
                unzip -q "$temp_file" -d "$install_dir" 2>/dev/null
                ;;
            xz)
                tar -xJf "$temp_file" -C "$install_dir" 2>/dev/null
                ;;
            *)
                error "Unsupported file extension: $extension"
                return 1
                ;;
        esac
        info "✓ Extraction complete"
    fi

    move_contents_and_remove_subfolder "$install_dir"
}

function move_contents_and_remove_subfolder() {
    target_dir="$1"
    
    # Check if there is only one subdirectory and no files in the target directory
    subdir=$(find "$target_dir" -mindepth 1 -maxdepth 1 -type d)

    if [ -d "$subdir" ]; then
        # Check if there are no files in the target directory
        if [ -z "$(find "$target_dir" -maxdepth 1 -type f)" ]; then
            # Rename subdirectory to a temporary name to avoid conflicts
            temp_name="_temp_extract_$$"
            temp_dir="$target_dir/$temp_name"
            
            mv "$subdir" "$temp_dir"
            
            # Move contents of the temporary directory to the target directory
            for item in "$temp_dir"/*; do
                mv "$item" "$target_dir/"
            done
            
            # Remove the now-empty temporary subdirectory
            rmdir "$temp_dir" 2>/dev/null
        fi
    fi
}

function install_dependencies() {
    local lib=$1
    local lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    check_file_exists $lib_config_file

    # Get the dependencies for the library (if they exist)
    local dependencies=$(yq eval ".installation.dependencies // []" "$lib_config_file")

    # If there are dependencies, install them
    if [ "$dependencies" != "null" ] && [ "$dependencies" != "[]" ]; then
        cleaned_dependencies=$(echo $dependencies | tr -d '[]" ')
        for dep in $cleaned_dependencies; do
            dep="${dep#-}"
            info "Installing dependency: $dep"
            configure "$dep"
        done
    fi
}

function check_file_exists() {
    local file_path=$1
    if [ ! -f "$file_path" ]; then
        error "Configuration file not found: $file_path"
        return 1
    fi
    return 0
}

function configure() {
    local lib=$1


    # Install dependencies first if they're required by other libs
    install_dependencies "$lib"   
    
    print_step "Configuring $lib"

    lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    check_file_exists $lib_config_file

    # Retrieve the default version of the library (already evaluated)
    local lib_version=$(get_default_version "$lib")

    local variable_name=$(get_default_version_key "$lib")
    info "✓ Using $lib version: $lib_version (override: export $variable_name=<version>)" >&2


    local installation_url=$(get_installation_url "$lib_version" "$lib_config_file")
    local installation_script=$(yq eval ".installation.script.\"$lib_version\" // \"\"" "$lib_config_file")

    # Check if either installation_url or installation_script has a value
    if [ -z "$installation_url" ] && [ -z "$installation_script" ]; then
        error "No installation method found for $lib version $lib_version"
        exit 1
    fi
    
    local run_post_installation=false
    local install_dir="${DOX_RESOURCES_DIR}/${lib}/${lib_version}"

    if [ -n "$installation_url" ]; then
        if [ ! -d "$install_dir" ] || [ -z "$(ls -A "$install_dir")" ]; then
            rm -rf "$install_dir"
            #info "✓ Found default URL: $installation_url" >&2
            download_and_extract "$installation_url" "$install_dir"
            run_post_installation=true
        else
            info "✓ Already installed: $lib $lib_version"
        fi
    else
        eval "$installation_script"
    fi

    # Set environment variables for the library
    configure_env_variables "$lib" "$lib_version" "$install_dir"

    if $run_post_installation; then
        run_installation_script "$lib" ".installation.post_installation_script"
    fi
    
    run_installation_script "$lib" ".configuration.post_configuration_script"

    echo ""
}

function replace_install_dir_vars() {
    local lib="$1"
    local script_file="$2"
    local lib_version=$(get_default_version "$lib")
    
    export lib_version=$(eval echo "$lib_version")
    export install_dir="${DOX_RESOURCES_DIR}/${lib}/${lib_version}"
    
    # Use envsubst to replace variables
    envsubst < "$script_file" > "${script_file}.tmp"
    mv "${script_file}.tmp" "$script_file"
    
    # Clean up the exported variable
    unset install_dir
}

function run_installation_script(){
    local lib=$1
    local script_path=$2
    local lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    check_file_exists $lib_config_file

    # Extract the script value using yq
    script=$(yq eval "${script_path} // \"\"" "$lib_config_file")

    # Check if the script is empty, if it's not, then run it
    if [[ -n "$script" ]]; then
        # Create a temporary file for the script
        temp_script_file=$(mktemp /tmp/temp_script.XXXXXX)

        # Write the script to the temporary file
        echo "$script" > "$temp_script_file"

        replace_install_dir_vars $lib $temp_script_file

        # Make the temporary script executable
        chmod +x "$temp_script_file"

        # Execute the temporary script
        source $temp_script_file
        if [[ $? -ne 0 ]]; then
            error "Script execution failed: $script_path"
            exit 1
        fi
        
        # Remove the temporary script file
        rm -f "$temp_script_file"
    fi
}

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    warn "No argument provided. Example: configure jdk"
else  
    # Iterate over all the provided arguments and call configure for each
    for tool in "$@"; do
        configure "$tool"
    done
fi
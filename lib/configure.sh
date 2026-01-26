#!/bin/bash

#Optional: As its already configured in dox
export DOX_DIR="${DOX_DIR:-$HOME/.dox}"
export DOX_CUSTOM_DIR="${DOX_CUSTOM_DIR:-$DOX_DIR/customize}"
export DOX_RESOURCES_DIR="${DOX_RESOURCES_DIR:-$HOME/dox_resources}"

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

function list_available_configurations() {
    info "📋 Available configurations:"
    echo ""
    
    if [ ! -d "$CONFIGURE_FILE_PATH" ]; then
        error "Configuration directory not found: $CONFIGURE_FILE_PATH"
        return 1
    fi
    
    local count=0
    printf "%-2s %-15s %-20s\n" "SL" "Tool" "Override"
    printf "%-2s %-15s %-20s\n" "--" "----" "--------"
    for config_file in "$CONFIGURE_FILE_PATH"/*.yaml; do
        if [ -f "$config_file" ]; then
            local filename=$(basename "$config_file" .yaml)
            local variable_name=$(get_default_version_key "$filename")

            # Skip files starting with underscore
            if [[ ! "$filename" =~ ^_ ]]; then
                ((count++))
                printf "%-2s %-15s %-20s\n" "$count" "$filename" "$variable_name"
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        warn "No configuration files found"
    else
        echo ""
        info "Total: $count configuration(s) available"
    fi
}

function configure_from_file() {
    local config_file=$1
    
    if [ ! -f "$config_file" ]; then
        error "Configuration file not found: $config_file"
        exit 1
    fi
    
    info "📄 Configuring from: $config_file"
    echo ""
    
    # Read the YAML file and extract tool configurations
    local tools=$(yq eval 'keys | .[]' "$config_file")
    
    if [ -z "$tools" ]; then
        error "No tools found in configuration file"
        exit 1
    fi
    
    # Process each tool
    while IFS= read -r tool; do
        local version=$(yq eval ".$tool.version" "$config_file")
        local variable_name=$(get_default_version_key "$tool")

        if [ -n "$version" ] && [ "$version" != "null" ] && [ -n "$variable_name" ] && [ "$variable_name" != "null" ]; then
            # Export the version variable temporarily for this configuration
            export "$variable_name=$version"
            configure "$tool"
            unset "$variable_name"
        else
            configure "$tool"
        fi
    done <<< "$tools"
    
    echo ""
    info "✓ Configuration complete"
}

function configure_env_variables() {
    local lib=$1
    local version=$2
    local install_dir=$3

    # Check if the 'envs' section exists
    local envs=$(yq eval ".configuration.environments // []" "$CONFIGURE_FILE_PATH/$lib.yaml")
    
    # Export variables for YAML evaluation
    export lib="$lib"
    export version="$version"
    export install_dir="${DOX_RESOURCES_DIR}/${lib}/${version}"

    # If environments exist, process them
    if [ "$envs" != "[]" ]; then
        while IFS="=" read -r key value; do
            # Evaluate variables in the value
            evaluated_value=$(eval echo "$value")
            
            if [ "$key" == "PATH" ]; then
                # Prepend to existing PATH
                local new_path="${evaluated_value}:${PATH}"
                update_dox_env "PATH" "$new_path"
                export PATH="$new_path"
                debug "PATH updated: $evaluated_value"
            else
                # Regular environment variable
                update_dox_env "$key" "$evaluated_value"
                export "$key=$evaluated_value"
                debug "$key set: $evaluated_value"
            fi
        done < <(echo "$envs" | yq eval '. | to_entries | .[] | "\(.key)=\(.value)"' -)
    fi
    
    # Clean up
    unset lib version install_dir
    
    # Source environment for post scripts
    if [[ -f "$DOX_ENV" ]]; then
        source "$DOX_ENV"
    fi
}

function update_dox_env() {
  local key="$1"
  local value="$2"
  local file="${DOX_ENV}"

  # Create file if it doesn't exist
  if [ ! -f "$file" ]; then
    touch "$file"
    echo "#!/bin/bash" > "$file"
    echo "# DOX Environment Variables" >> "$file"
    echo "# Source this file: source ./dox_env" >> "$file"
    echo "" >> "$file"
  fi

  # Special handling for PATH - avoid duplicates
  if [ "$key" == "PATH" ]; then
    # Extract the new path component (before the first colon)
    local new_path_component="${value%%:*}"
    
    # Check if this path is already in the file
    if grep -q "export PATH=.*${new_path_component}" "$file" 2>/dev/null; then
      debug "PATH already contains: $new_path_component"
      return 0
    fi
    
    # Check if PATH variable exists in file
    if grep -q "^export PATH=" "$file" 2>/dev/null; then
      # Update existing PATH by prepending new component
      local existing_path=$(grep "^export PATH=" "$file" | head -1 | sed 's/^export PATH="//' | sed 's/"$//')
      local updated_path="${new_path_component}:${existing_path}"
      
      # Remove old PATH lines
      grep -v "^export PATH=" "$file" > "${file}.tmp" 2>/dev/null || touch "${file}.tmp"
      
      # Add updated PATH
      echo "export PATH=\"${updated_path}\"" >> "${file}.tmp"
      
      mv "${file}.tmp" "$file"
      debug "PATH updated with: $new_path_component"
      return 0
    fi
  fi

  # For non-PATH variables: check if already exists with same value
  if grep -q "^export ${key}=" "$file" 2>/dev/null; then
    local existing_value=$(grep "^export ${key}=" "$file" | head -1 | sed "s/^export ${key}=//" | tr -d '"')
    
    if [ "$existing_value" == "$value" ]; then
      debug "$key already set: $value"
      return 0
    else
      debug "Updating $key: $existing_value → $value"
    fi
  fi

  # Remove existing key (if exists)
  grep -v "^export $key=" "$file" > "${file}.tmp" 2>/dev/null || touch "${file}.tmp"
  
  # Add updated key=value with export
  echo "export $key=\"$value\"" >> "${file}.tmp"

  # Replace original file
  mv "${file}.tmp" "$file"
  chmod +x "$file"
}

function download_and_extract() {
    local lib_url=$1
    local install_dir=$2
    local rename=$3
    local make_executable=$4
    local temp_file=$(mktemp)

    local filename="${rename:-$(basename "$lib_url")}"

    # Create target directory
    mkdir -p "$install_dir"

    # Download the file
    info "⬇ Downloading $filename from $lib_url"
    download_tool_to_configure "$lib_url" "$temp_file"

    # Get file size and print it
    local file_size=$(stat -f%z "$temp_file" 2>/dev/null || stat -c%s "$temp_file" 2>/dev/null)

    # Check if downloaded file is empty
    if [[ $file_size -lt 1024 ]]; then
        error "Download failed: $lib_url" >&2
        rm -f "$temp_file"
        exit 1
    fi

    # Get the extension
    local extension="${filename##*.}"

    # Check if the file has an extension
    if [[ "$filename" == "$extension" ]]; then
        # No extension, assume it's a regular file and copy
        mv "$temp_file" "$install_dir/$filename"

        # If make_executable is true, set executable permission
        if [[ "$make_executable" == "true"  ]]; then
            info "⚙ Making $filename executable"
            chmod +x "${install_dir}/${filename}"
        fi

        debug "Download complete: $filename"
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
                rm -f "$temp_file"
                return 1
                ;;
        esac
        debug "Extraction complete: $filename"
    fi

    # Clean up temp file if it still exists
    rm -f "$temp_file"

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
            debug "Installing dependency: $dep"
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
    
    lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    check_file_exists $lib_config_file

    # Retrieve the default version of the library (already evaluated)
    local lib_version=$(get_default_version "$lib")

    # Update DOX_ENV with the version variable
    local get_default_version_key=$(get_default_version_key "$lib")
    update_dox_env $get_default_version_key "$lib_version"

    local installation_url=$(get_installation_url "$lib_version" "$lib_config_file")

    # Read template separately
    local installation_script_template=$(yq eval ".installation.script.template // \"\"" "$lib_config_file")

    local installation_script=$(yq eval ".installation.script.\"$lib_version\" // \"\"" "$lib_config_file")

    # Check if either installation_url or installation_script has a value
    if [ -z "$installation_url" ] && [ -z "$installation_script" ] && [ -z "$installation_script_template" ]; then
        error "No installation method found for $lib version $lib_version"
        exit 1
    fi
    
    export install_dir="${DOX_RESOURCES_DIR}/${lib}/${lib_version}"

    if [ -n "$installation_url" ]; then
        if [ ! -d "$install_dir" ] || [ -z "$(ls -A "$install_dir")" ]; then
            rm -rf "$install_dir"
            download_rename=$(yq eval '.installation.download.rename // ""' "$lib_config_file")
            download_executable=$(yq eval '.installation.download.executable // false' "$lib_config_file")

            download_and_extract "$installation_url" "$install_dir" "$download_rename" "$download_executable"
            run_installation_script "$lib" ".installation.post_installation_script" $lib_version
        fi
        info "✓ Configuring $lib $lib_version"
    else
        if [ -n "$installation_script_template" ]; then
            installation_script=$(echo "$installation_script_template" | sed "s/{version}/$lib_version/g")
        fi
        debug "Using installation script for $lib"
        eval "$installation_script"
        info "✓ Configuring $lib $lib_version"
    fi

    # Set environment variables for the library
    configure_env_variables "$lib" "$lib_version" "$install_dir"
    
    run_installation_script "$lib" ".configuration.post_configuration_script" $lib_version
}


function run_installation_script(){
    local lib=$1
    local script_path=$2
    local lib_version=$3
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
        
        # Make the temporary script executable
        chmod +x "$temp_script_file"
        
        # Export variables that the script needs
        export lib="$lib"
        export lib_version=$(eval echo "$lib_version")
        export install_dir="${DOX_RESOURCES_DIR}/${lib}/${lib_version}"
        
        # Execute the temporary script
        source $temp_script_file
        
        if [[ $? -ne 0 ]]; then
            error "Script execution failed: $script_path"
            exit 1
        fi
        
        # Clean up exported variables
        unset lib lib_version install_dir
        
        # Remove the temporary script file
        rm -f "$temp_script_file"
    fi
}


# Main execution logic
if [ $# -eq 0 ]; then
    # No arguments: list available configurations
    list_available_configurations
elif [ "$1" == "list" ]; then
    # Explicit list command
    list_available_configurations
elif [ "$1" == "-f" ]; then
    # Configure from file
    if [ $# -lt 2 ]; then
        error "Error: -f option requires a file path"
        echo "Usage: dox configure -f <config-file>"
        exit 1
    fi
    configure_from_file "$2"
else  
    # Iterate over all the provided arguments and call configure for each
    for tool in "$@"; do
        configure "$tool"
    done
fi
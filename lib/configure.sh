#!/bin/bash

#Optional: As its already configured in dox
export DOX_DIR="${DOX_DIR:-$HOME/.dox}"
export DOX_CUSTOM_DIR="${DOX_CUSTOM_DIR:-$DOX_DIR/customize}"
export DOX_RESOURCES_DIR="${DOX_RESOURCES_DIR:-$HOME/dox_resources}"
export DOX_USER_BIN="${DOX_USER_BIN:-/usr/local/bin/}"
export DOX_ENV="dox_env"

source ${DOX_DIR}/lib/shared/env_handler.sh
source ${DOX_DIR}/lib/shared/print.sh
source ${DOX_CUSTOM_DIR}/download_files.sh

# configuration yaml location
CONFIGURE_FILE_PATH="${DOX_CUSTOM_DIR}/configure"

print_envs DOX_RESOURCES_DIR CONFIGURE_FILE_PATH DOX_DIR DOX_CUSTOM_DIR

# Function to set environment variables for a given library
function configure_env_variables() {
    local lib=$1
    local version=$2
    local install_dir=$3

    info "Setting environment variables for $lib version $version..."

    # Check if the 'envs' section exists in the JSON for this library
    local envs=$(yq eval ".configuration.environments // []" "$CONFIGURE_FILE_PATH/$lib.yaml")

    # If 'envs' exists, process and set the environment variables
    if [ "$envs" == "[]" ]; then
        echo "No environments found or the key is missing/empty for for $lib."
    else
        #echo "Environmet Variables : $envs" 
        # Iterate over each element in the 'envs' array
        echo "$envs" | yq eval '. | to_entries | .[] | "\(.key)=\(.value)"' - | while IFS="=" read -r key value; do
            # Print the $key and $value for debugging
            # Evaluate and export the environment variable:
            local evaluated_value=$(eval echo "$value")
            # Print the evaluated value
            #echo "Evaluated Value: $evaluated_value"
            if [ "$key" == "PATH" ]; then # 
                create_symlinks_to_bin "$evaluated_value"
            else # For other keys, save them to the env.sh script
                update_dox_env $key $evaluated_value
            fi
        done
    fi
    # used for post_installation_scripts
    if [[ -f "$DOX_ENV" ]]; then
        source "$DOX_ENV"
    fi
}

function create_symlinks_to_bin() {
  local source_folder="$1"
  local bin_folder="${DOX_USER_BIN}"

  if [ ! -d "$source_folder" ]; then
    echo "❌ Source folder '$source_folder' does not exist."
    return 1
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
        echo "🔗 Linked $filename to $bin_folder"
      else
        debug "⚠️ Skipping non-executable: $filename"
      fi
    fi
  done
}

function download_and_extract() {
    local lib_url=$1
    local install_dir=$2
    local temp_file=$(mktemp)

    # Create target directory
    mkdir -p "$install_dir"

    # Download the file
    echo -e "\033[0;32mDownloading to temp file $temp_file\033[0m"
    download_tool_to_configure "$lib_url" "$temp_file"

    echo -e "\033[0;32mDownload completed. Extracting to $install_dir\033[0m"

    # Get the file name and extension
    local filename=$(basename "$lib_url")
    local extension="${filename##*.}"

    # Check if the file has an extension
    if [[ "$filename" == "$extension" ]]; then
        # No extension, assume it's a regular file and copy ( Example kubectl )
        mv "$temp_file" "$install_dir/$filename" && echo "Moving $filename to: $install_dir"
    else
        # File has an extension, determine its type and extract accordingly
        case "$extension" in
            gz|tgz)
                tar -xzf "$temp_file" -C "$install_dir" && echo "Extracting tar.gz or tgz"
                ;;
            zip)
                unzip "$temp_file" -d "$install_dir" && echo "Unzipping zip"
                ;;
            xz)
                tar -xJf "$temp_file" -C "$install_dir" && echo "Extracting tar.xz"
                ;;
            *)
                error "Unsupported file extension: $extension" && return 1
                ;;
        esac
    fi

    info "Extraction successful. Library installed to $install_dir"
    move_contents_and_remove_subfolder "$install_dir"

    echo "Downloaded and extracted the library to $install_dir."
}



# Define the move_contents_and_remove_subfolder function
function move_contents_and_remove_subfolder() {
    target_dir="$1"  # Get target directory as argument
    
    # Check if there is only one subdirectory and no files in the target directory
    subdir=$(find "$target_dir" -mindepth 1 -maxdepth 1 -type d)

    if [ -d "$subdir" ]; then
        # Check if there are no files in the target directory
        if [ -z "$(find "$target_dir" -maxdepth 1 -type f)" ]; then
            # Move contents of the subdirectory to the target directory
            mv "$subdir"/* "$target_dir"
            
            # Remove the now-empty subdirectory
            rmdir "$subdir"
            
            echo "Moved contents of the subdirectory and removed the empty subdirectory."
        else
            echo "There are files in the target directory, skipping the move."
        fi
    else
        echo "No subdirectory found, skipping the move."
    fi
    # List the contents of the target directory with detailed and colorized output
    echo ""
    echo "$target_dir"
    ls -l --color=auto "$target_dir"
    echo ""
}


# Generic function to install dependencies for a given library
function install_dependencies() {
    local lib=$1
    local lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    check_file_exists $lib_config_file

    # Get the dependencies for the library (if they exist)
    local dependencies=$(yq eval ".installation.dependencies // []" "$lib_config_file")

    # If there are no dependencies, return
    if [ "$dependencies" == "null" ] || [ "$dependencies" == "[]" ]; then
         print "Dependency check completed, NO dependencies found for $lib."
    else
        # Iterate through dependencies and install each
        cleaned_dependencies=$(echo $dependencies | tr -d '[]" ')
        for dep in $cleaned_dependencies; do
            dep="${dep#-}"
            print "Installing dependency: $dep..."
            configure "$dep"
        done
    fi
}

function check_file_exists() {
    local file_path=$1
    # Check if the file exists
    if [ ! -f "$file_path" ]; then
        error "Error: File $file_path not found!"
        return 1
    fi
    return 0
}

# Generic function to install any library based on the library name
function configure() {
    local lib=$1

    # Install dependencies first if they're required by other libs
    install_dependencies "$lib"   
    
    print_step "Configuring $lib"
    info  "Installing $lib..."

    lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    
    check_file_exists $lib_config_file

    echo -e "Configuration file: \033[0;36m$lib_config_file\033[0m"

    # Retrieve the default version of the library from the JSON
    local lib_version=$(yq eval -r ".configuration.default_version" "$lib_config_file")
    
    variable_name=$(echo "$lib_version" | perl -nle 'print $1 if /\${([^:]+):/')
    echo -e "You can override the version by providing a value for the variable \033[0;35m$variable_name\033[0m"
    echo -e "Evaluating library version: \033[0;33m$lib_version\033[0m"

    # Evaluate shell variable expansion for the default version
    lib_version=$(eval echo "$lib_version")
    #Exporting variable name 
    export "$variable_name"="$lib_version"

    echo -e "Resolved $lib version: \033[0;33m$lib_version\033[0m"

    # Check if the version is empty
    if [ -z "$lib_version" ]; then
        error "Error: No version specified for $lib"
        return 1
    fi

    # Using yq to evaluate the keys and set to empty string if they don't exist ( installation.download.123 or installation.download.123.)
    local installation_url=$(yq eval ".installation.download.\"$lib_version\".\"$(uname -m)\" // .installation.download.\"$lib_version\" // \"\"" "$lib_config_file")
    local installation_script=$(yq eval ".installation.script.\"$lib_version\" // \"\"" "$lib_config_file")

    # Check if either installation_url or installation_script has a value
    if [ -z "$installation_url" ] && [ -z "$installation_script" ]; then
        error "Error: Neither installation download URL nor install script found for $lib_version. Exiting."
        debug ".installation.download.$lib_version.$(uname -m) - verify " 
        debug ".installation.script.$lib_version - verify " 
        debug "x86_64: Intel/AMD 64-bit (Ubuntu, macOS, Windows); armv7l: ARM 32-bit (Raspberry Pi 2, older Android); aarch64: ARM 64-bit (Raspberry Pi 3/4, Apple M1, ARM Servers); ppc64le: PowerPC 64-bit (IBM Power Systems)"
        exit 1
    fi
    
    local run_post_installation=false

    if [ -n "$installation_url" ]; then # If installation_url exists give more priority to this
        local install_dir="${DOX_RESOURCES_DIR}/${lib}/${lib_version}"
        if [ ! -d "$install_dir" ] || [ -z "$(ls -A "$install_dir")" ]; then # If the directory does not exist or is empty
            rm -rf "$install_dir" #Handling empty condition
            echo -e "Download URL: \033[0;36m$installation_url\033[0m"
            echo -e "Installation Directory: \033[0;36m$install_dir\033[0m"
            info "$lib version $lib_version is not installed. Installing..."
            download_and_extract "$installation_url" "$install_dir"
            run_post_installation=true
        else # If the directory exists and is not empty
           echo "$lib version $lib_version already installed at $install_dir"
        fi
    else
        echo "Installation Script: $installation_script"
        eval "$installation_script"
    fi

    # Set environment variables for the library
    configure_env_variables "$lib" "$lib_version" "$install_dir"

    if $run_post_installation; then
        run_installation_script "$lib" ".installation.post_installation_script"
    fi
    
    run_installation_script "$lib" ".configuration.post_configuration_script"

    echo ""
    echo -e "\033[0;32m$lib installation completed successfully.\033[0m"
    echo ""
}

function replace_install_dir_vars() {
    local lib="$1"
    local lib_version=$(yq eval -r ".configuration.default_version" "$CONFIGURE_FILE_PATH/$lib.yaml")
    local install_dir="${DOX_RESOURCES_DIR}/${lib}/${lib_version}"
    debug "Replacing \${install_dir} with ${install_dir}"
    sed -i "s|\${install_dir}|$install_dir|g" "$2"
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
        # Print script and debug info
        print "34" "40" "🚀[$lib] Running $script_path script"  # Yellow text on black background

        # Create a temporary file for the script
        temp_script_file=$(mktemp /tmp/temp_script.XXXXXX)

        # Write the script to the temporary file
        echo "$script" > "$temp_script_file"

        replace_install_dir_vars $lib $temp_script_file #Replacing all the string variables ${install_dir} with actual path

        # Make the temporary script executable
        chmod +x "$temp_script_file"

        # Execute the temporary script
        source $temp_script_file  # Execute the script on the same shell (!IMPORTANT)

        # Optionally, remove the temporary script file after execution
        rm -f "$temp_script_file"
    else
        debug "No script found $lib_config_file in $script_path for $lib. Skipping script execution."
    fi
}

# Example installation of JDK and Maven
#configure jdk

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    # No argument provided, print a message
    warn "No argument provided. Example: configure jdk"
else  
    # Iterate over all the provided arguments and call configure for each
    for tool in "$@"; do
        echo "Configuring tool: $tool"
        configure "$tool"
    done
fi

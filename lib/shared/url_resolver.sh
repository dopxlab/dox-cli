#!/bin/bash

# Detect OS type
function detect_os() {
    local os_type=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="mac"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
        os_type="linux"
    else
        os_type="unknown"
    fi
    echo "$os_type"
}

# Detect and normalize architecture
function detect_architecture() {
    local architecture=$(uname -m)
    
    # Normalize to "arm64" if it's aarch64
    if [[ "$architecture" == "aarch64" ]]; then
        architecture="arm64"
    fi
    
    echo "$architecture"
}

# Apply OS mapping from configuration
function apply_os_mapping() {
    local os_type=$1
    local lib_config_file=$2
    
    # Get OS mapping if defined, otherwise return original
    local mapped_os=$(yq eval ".installation.download.mappings.os.\"$os_type\" // \"$os_type\"" "$lib_config_file")
    echo "$mapped_os"
}

# Apply architecture mapping from configuration
function apply_arch_mapping() {
    local architecture=$1
    local lib_config_file=$2
    
    # Get architecture mapping if defined, otherwise return original
    local mapped_arch=$(yq eval ".installation.download.mappings.arch.\"$architecture\" // \"$architecture\"" "$lib_config_file")
    echo "$mapped_arch"
}

# Generate URL from template with variable substitution
function generate_url_from_template() {
    local template=$1
    local version=$2
    local os_type=$3
    local architecture=$4
    
    # Replace placeholders in template
    local url="$template"
    url="${url//\{version\}/$version}"
    url="${url//\{os\}/$os_type}"
    url="${url//\{arch\}/$architecture}"
    
    echo "$url"
}

# Get installation URL from template (NEW METHOD)
function get_installation_url_from_template() {
    local lib_version=$1
    local lib_config_file=$2
    local os_type=$3
    local architecture=$4
    
    # Check if template exists
    local template=$(yq eval ".installation.download.template // \"\"" "$lib_config_file")
    
    if [[ -z "$template" ]]; then
        debug "No template found in configuration" >&2
        echo ""
        return 1
    fi
    
    info "Found template: $template" >&2
    
    # Apply OS mapping
    local mapped_os=$(apply_os_mapping "$os_type" "$lib_config_file")
    info "OS mapping: $os_type -> $mapped_os" >&2
    
    # Apply architecture mapping
    local mapped_arch=$(apply_arch_mapping "$architecture" "$lib_config_file")
    info "Architecture mapping: $architecture -> $mapped_arch" >&2
    
    # Generate URL from template
    local installation_url=$(generate_url_from_template "$template" "$lib_version" "$mapped_os" "$mapped_arch")
    
    info "Generated URL from template: $installation_url" >&2
    echo "$installation_url"
    return 0
}

# Get installation URL from explicit URL definitions (EXISTING METHOD)
function get_installation_url_from_url() {
    local lib_version=$1
    local lib_config_file=$2
    local os_type=$3
    local architecture=$4
    
    # Build platform key (e.g., "mac-arm64", "linux-x86_64")
    local platform_key="${os_type}-${architecture}"
    
    debug "Looking for explicit URLs for version: $lib_version" >&2

    # Priority 1: Try platform-specific URL (e.g., .installation.download.28.1.1.mac-arm64)
    local installation_url=$(yq eval ".installation.download.\"$lib_version\".\"$platform_key\" // \"\"" "$lib_config_file")

    if [[ -n "$installation_url" ]]; then
        info "Found platform-specific URL: $platform_key" >&2
        echo "$installation_url"
        return 0
    fi

    # Priority 2: Fallback to architecture-only (e.g., .installation.download.28.1.1.arm64)
    debug "'$platform_key' specific URL not found, checking for architecture-only configuration" >&2
    debug "$architecture: $(get_arch_description "$architecture")" >&2
    installation_url=$(yq eval ".installation.download.\"$lib_version\".\"$architecture\" // \"\"" "$lib_config_file")

    if [[ -n "$installation_url" ]]; then
        info "Found architecture-specific URL: $architecture" >&2
        echo "$installation_url"
        return 0
    fi

    # Priority 3: Final fallback to version-only (e.g., .installation.download.28.1.1 as direct string)
    debug "Architecture-specific URL not found, checking for default version URL" >&2
    installation_url=$(yq eval ".installation.download.\"$lib_version\" // \"\"" "$lib_config_file")
    
    if [[ -n "$installation_url" ]]; then
        info "Found version-only URL" >&2
        echo "$installation_url"
        return 0
    fi
    
    # Nothing found
    debug "No explicit URL found for version: $lib_version" >&2
    echo ""
    return 1
}

# Main function to get installation URL (orchestrates both methods)
function get_installation_url() {
    local lib_version=$1
    local lib_config_file=$2
    
    # Detect OS and architecture
    local os_type=$(detect_os)
    local architecture=$(detect_architecture)

    info "Identified OS: $os_type" >&2
    info "Identified architecture: $architecture" >&2

    local installation_url=""
    
    # Strategy:
    # 1. First, try to get explicit URL (highest priority - allows overrides)
    # 2. If not found, try template-based generation
    # 3. If neither works, return empty string
    
    # Try explicit URL first (this allows specific versions to override templates)
    installation_url=$(get_installation_url_from_url "$lib_version" "$lib_config_file" "$os_type" "$architecture")
    
    if [[ -n "$installation_url" ]]; then
        info "Using explicit URL definition" >&2
        echo "$installation_url"
        return 0
    fi
    
    # Explicit URL not found, try template
    debug "No explicit URL found, attempting template-based generation" >&2
    installation_url=$(get_installation_url_from_template "$lib_version" "$lib_config_file" "$os_type" "$architecture")
    
    if [[ -n "$installation_url" ]]; then
        info "Using template-generated URL" >&2
        echo "$installation_url"
        return 0
    fi
    
    # Nothing found
    debug "Could not determine installation URL from either explicit definitions or template" >&2
    echo ""
    return 1
}

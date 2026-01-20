#!/bin/bash

# =============================================================================
# VERSION MANAGEMENT SYSTEM
# =============================================================================
# Version resolution with environment variable export and file caching.
#
# FLOW:
# Step 1: Check if environment variable (e.g., DOCKER_CLI_VERSION) already exists
#         - If YES: Return its value silently
# Step 2: Evaluate default_version expression (may include curl/API calls)
#         - If SUCCESS:
#           a. Export the variable (e.g., export DOCKER_CLI_VERSION="28.1.1")
#           b. Save to cache file
#           c. Return the value
# Step 3: If evaluation returns null/empty, fall back to cache file
#         - If cache found: Return cached value
#         - If no cache: Exit with error
#
# CACHE FILE: ${DOX_RESOURCES_DIR}/versions.yaml
# =============================================================================

VERSIONS_CACHE_FILE="${DOX_RESOURCES_DIR}/versions.yaml"

# =============================================================================
# FUNCTION: get_default_version_key
# =============================================================================
# Extracts the environment variable name from the version configuration
# without evaluating the expression.
#
# Example:
#   If config has: ${DOCKER_CLI_VERSION:-29.1.5}
#   Returns: DOCKER_CLI_VERSION
#
# Returns empty string if no variable pattern is found.
# =============================================================================
function get_default_version_key() {
    local lib=$1
    local lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    
    # Check if config file exists
    if [ ! -f "$lib_config_file" ]; then
        echo ""
        return 1
    fi
    
    # Read raw config (no evaluation)
    local lib_version_raw=$(yq eval -r ".configuration.default_version" "$lib_config_file")
    
    if [ -z "$lib_version_raw" ] || [ "$lib_version_raw" == "null" ]; then
        echo ""
        return 1
    fi
    
    # Extract variable name (e.g., DOCKER_CLI_VERSION from ${DOCKER_CLI_VERSION:-...})
    local variable_name=""
    if [[ $lib_version_raw =~ \$\{([^:}]+) ]]; then
        variable_name="${BASH_REMATCH[1]}"
    fi
    
    echo "$variable_name"
    return 0
}

# =============================================================================
# FUNCTION: get_default_version
# =============================================================================
function get_default_version() {
    local lib=$1
    local lib_config_file="$CONFIGURE_FILE_PATH/$lib.yaml"
    
    # Check if config file exists
    if [ ! -f "$lib_config_file" ]; then
        error "Configuration file not found: $lib_config_file" >&2
        return 1
    fi
    
    # Read raw config (no evaluation yet)
    local lib_version_raw=$(yq eval -r ".configuration.default_version" "$lib_config_file")
    
    if [ -z "$lib_version_raw" ] || [ "$lib_version_raw" == "null" ]; then
        error "No default_version found in $lib_config_file" >&2
        return 1
    fi
    
    # Extract variable name using the dedicated function
    local variable_name=$(get_default_version_key "$lib")
    
    # ==========================================================================
    # STEP 1: Check if environment variable already exists (SILENT)
    # ==========================================================================
    if [ -n "$variable_name" ]; then
        local env_value="${!variable_name}"
        if [ -n "$env_value" ]; then
            echo "$env_value"
            return 0
        fi
    fi
    
    # ==========================================================================
    # STEP 2: Evaluate default_version expression
    # ==========================================================================
    local evaluated_version=$(eval echo "$lib_version_raw" 2>&1)
    local eval_exit_code=$?
    
    # Check if evaluation succeeded
    if [ $eval_exit_code -eq 0 ] && [ -n "$evaluated_version" ] && [ "$evaluated_version" != "null" ] && [ "$evaluated_version" != "" ]; then
        
        # STEP 2a: Export the variable (so it persists in the shell)
        if [ -n "$variable_name" ]; then
            export "$variable_name=$evaluated_version"
        fi
        
        # STEP 2b: Save to cache file
        if [ ! -f "$VERSIONS_CACHE_FILE" ]; then
            mkdir -p "$(dirname "$VERSIONS_CACHE_FILE")" 2>/dev/null
            echo "---" > "$VERSIONS_CACHE_FILE"
        fi
        
        yq eval -i ".${lib}.version = \"${evaluated_version}\"" "$VERSIONS_CACHE_FILE" 2>/dev/null
        yq eval -i ".${lib}.last_updated = $(date +%s)" "$VERSIONS_CACHE_FILE" 2>/dev/null
        if [ -n "$variable_name" ]; then
            yq eval -i ".${lib}.variable_name = \"${variable_name}\"" "$VERSIONS_CACHE_FILE" 2>/dev/null
        fi
        
        # Show version info with override hint
        if [ -n "$variable_name" ]; then
            info "✓ Using $lib version: $evaluated_version (override: export $variable_name=<version>)" >&2
        else
            info "✓ Using $lib version: $evaluated_version" >&2
        fi
        
        # STEP 2c: Return the value
        echo "$evaluated_version"
        return 0
    fi
    
    # ==========================================================================
    # STEP 3: Evaluation failed/returned null - Fall back to cache
    # ==========================================================================
    if [ -f "$VERSIONS_CACHE_FILE" ]; then
        local cached_version=$(yq eval -r ".${lib}.version // \"\"" "$VERSIONS_CACHE_FILE" 2>/dev/null)
        
        if [ -n "$cached_version" ] && [ "$cached_version" != "null" ]; then
            warn "Using cached version: $cached_version (API call failed)" >&2
            
            # Export the cached version too
            if [ -n "$variable_name" ]; then
                export "$variable_name=$cached_version"
            fi
            
            echo "$cached_version"
            return 0
        fi
    fi
    
    # No cache found - Exit with error
    error "Cannot determine version for $lib" >&2
    return 1
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function clear_version_cache() {
    local lib=$1
    
    if [ ! -f "$VERSIONS_CACHE_FILE" ]; then
        warn "No cache file exists"
        return 0
    fi
    
    if [ -n "$lib" ]; then
        yq eval -i "del(.${lib})" "$VERSIONS_CACHE_FILE"
        info "Cache cleared for $lib"
    else
        rm -f "$VERSIONS_CACHE_FILE"
        info "All cache cleared"
    fi
}

function show_version_cache() {
    if [ -f "$VERSIONS_CACHE_FILE" ]; then
        echo "=== Version Cache ==="
        cat "$VERSIONS_CACHE_FILE"
        echo "===================="
    else
        warn "No cache file exists"
    fi
}
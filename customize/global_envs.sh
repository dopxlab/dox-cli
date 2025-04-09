#!/bin/bash

# Ensuring safe scripting
# - `-e`: Exit script on error.
# - `-u`: Treat unset variables as an error.
# - `-o pipefail`: Fail the script if any part of a pipeline fails.
#set -euo pipefail

# Source the git_helpers.sh file to load git-related helper functions
source "${DOX_DIR}/lib/shared/git_helpers.sh"

# Export Git-based environment variables for the current repository
# These variables are useful for logging, versioning, and deployment contexts
function get_workspace_path() {
    local workspace="$GITHUB_WORKSPACE"
    if [ -n "$BUILD_PATH" ]; then
        workspace="$GITHUB_WORKSPACE/$BUILD_PATH"
    fi   
    echo "$workspace"
}

function cd_workspace() {
    local workspace
    workspace=$(get_workspace_path)
    echo "Workspace: $workspace"
    # Change to the workspace directory
    cd "$workspace" || { echo "Failed to change directory to $workspace"; exit 1; }
}

cd_workspace

export GIT_REPOSITORY_NAME="$(get_git_repository_name)"  # Full repository name, e.g., 'my-repo'
export GIT_BRANCH_NAME="$(get_git_branch_name)"          # Current branch name, e.g., 'feature-xyz'
export GIT_BRANCH_PREFIX="$(get_git_branch_prefix)"      # Branch prefix (useful for feature, release, hotfix distinction)
export GIT_COMMITTER_NAME="$(get_git_committer_name)"    # Committer's name
export GIT_COMMITTER_EMAIL="$(get_git_committer_email)"  # Committer's email address
export GIT_COMMIT_URL="$(get_git_commit_url)"            # Full URL to the current commit on the remote
export GIT_COMMIT_ID="$(get_git_commit_id)"              # Full commit hash (SHA)
export GIT_COMMIT_SHORT_ID="$(get_git_commit_short_id)"  # Short commit hash (e.g., first 7 characters)
export GIT_COMMIT_MESSAGE="$(get_git_commit_message)"    # Full commit message

# Exported environment variables that are useful for versioning, builds, and deployments
# These variables are commonly used in CI/CD pipelines, Helm charts, etc.

function get_build_version() {
  # Get the current date in the format YYYYMMDD.HHMMSS
  pipeline_id=0
  timestamp=$(date +"%Y%m%d.%H%M%S")
  
  # Remove the leading zero from the hour (if applicable)
  formatted_timestamp=$(echo $timestamp | sed 's/\([0-9]\{8\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1\2\3/')

  # Output the formatted timestamp with the pipeline_id
  echo "$formatted_timestamp.$pipeline_id"
}


export APPLICATION_NAME="$GIT_REPOSITORY_NAME"    # Use the Git repository name as the application name
export BUILD_VERSION="${BUILD_VERSION:-$(get_build_version)}"

# The variables `APPLICATION_NAME` and `BUILD_VERSION` are used throughout the pipeline, 
# Helm chart deployment, and other related tools to ensure consistency and traceability.

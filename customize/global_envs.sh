#!/bin/bash

# Ensuring safe scripting
# - `-e`: Exit script on error.
# - `-u`: Treat unset variables as an error.
# - `-o pipefail`: Fail the script if any part of a pipeline fails.
set -euo pipefail

# Source the git_helpers.sh file to load git-related helper functions
source "${DOX_DIR}/shared/git_helpers.sh"

# Export Git-based environment variables for the current repository
# These variables are useful for logging, versioning, and deployment contexts

export GIT_REPOSITORY_NAME="$(get_git_repository_name)"  # Full repository name, e.g., 'my-repo'
export GIT_BRANCH_NAME="$(get_git_branch_name)"          # Current branch name, e.g., 'feature-xyz'
export GIT_BRANCH_PREFIX="$(get_git_branch_prefix)"      # Branch prefix (useful for feature, release, hotfix distinction)
export GIT_COMMITTER_NAME="$(get_git_committer_name)"    # Committer's name
export GIT_COMMITTER_EMAIL="$(get_git_committer_email)"  # Committer's email address
export GIT_COMMIT_URL="$(get_git_commit_url)"            # Full URL to the current commit on the remote
export GIT_COMMIT_ID="$(get_git_commit_id)"              # Full commit hash (SHA)
export GIT_COMMIT_SHORT_ID="$(get_git_commit_short_id)"  # Short commit hash (e.g., first 7 characters)
export GIT_COMMIT_MESSAGE="$(get_git_commit_message)"    # Full commit message

# Function to generate a version string based on the current date and time
# This helps to create a unique version string for each build or deployment.
# Format: YYYY.MM.DD.HHMMSS
# Example output: 2025.04.09.142310

function get_version() {
    local year=$(date +%Y)   # Get the current year (e.g., 2025)
    local month=$(date +%m)  # Get the current month (e.g., 04)
    local day=$(date +%d)    # Get the current day of the month (e.g., 09)
    local time=$(date +%H%M%S)  # Get the current time in HHMMSS format (e.g., 142310)

    # Return the version string
    echo "${year}.${month}.${day}.${time}"  # Result: e.g., '2025.04.09.142310'
}

# Exported environment variables that are useful for versioning, builds, and deployments
# These variables are commonly used in CI/CD pipelines, Helm charts, etc.

export APPLICATION_NAME="$GIT_REPOSITORY_NAME"    # Use the Git repository name as the application name
export BUILD_VERSION="$(get_version)"             # Generate the build version based on current date and time

# The variables `APPLICATION_NAME` and `BUILD_VERSION` are used throughout the pipeline, 
# Helm chart deployment, and other related tools to ensure consistency and traceability.

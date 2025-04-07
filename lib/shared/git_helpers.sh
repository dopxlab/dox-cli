#!/bin/bash

# Function to get the Git repository name
function get_git_repository_name() {
    local remote_url=$(git config --get remote.origin.url)
    local repo_name=$(basename "$remote_url" .git)
    echo "${repo_name}"
}

# Function to get the current Git branch name
function get_git_branch_name() {
    if [[ -n "$GITHUB_REF" && "$GITHUB_REF" == refs/heads/* ]]; then
        echo "${GITHUB_REF#refs/heads/}"
    else
        echo "unknown"
    fi
}

# Function to get the Git committer's sanitized name
function get_git_committer_name() {
    local git_committer_name=$(git -C . log -1 --pretty=format:'%an')
    # Remove leading and trailing spaces
    git_committer_name=$(echo "$git_committer_name" | sed 's/^[ \t]*//;s/[ \t]*$//')
    # Replace non-alphabetic characters with underscores
    git_committer_name=$(echo "$git_committer_name" | sed 's/[^a-zA-Z]/_/g')
    # Remove consecutive underscores
    git_committer_name=$(echo "$git_committer_name" | sed 's/_\+/_/g')
    echo "${git_committer_name}"
}

# Function to get the Git committer's email
function get_git_committer_email(){
    local git_committer_email=$(git -C . log -1 --pretty=format:'%ae')
    echo "${git_committer_email}"
}

# Function to get the URL of the current Git commit
function get_git_commit_url(){
    local input_url=$(git config --get remote.origin.url)
    local git_hash_id=$(git rev-parse HEAD)
    echo "${input_url/tatasteel-dod@/}/commit/${git_hash_id}"
}

# Function to get the current Git commit ID (hash)
function get_git_commit_id(){
    git rev-parse HEAD
}

# Function to get the short version of the current Git commit ID (short hash)
function get_git_commit_short_id(){
    git rev-parse --short HEAD
}

# Function to get the Git commit message
function get_git_commit_message(){
    local git_commit_message=$(git log -1 --pretty=%B)
    git_commit_message="$(echo "$git_commit_message" | tr -d '\n' | tr -d "'" | tr -d '"')"
    echo "${git_commit_message}"
}

function get_git_branch_prefix() {
    branch=$(get_git_branch_name)
    echo ${branch%%/*}
}

# Example usage:
# Uncomment the below lines for testing or usage example
# get_git_repository_name
# get_git_branch_name
# get_git_committer_name
# get_git_committer_email
# get_git_commit_url
# get_git_commit_message

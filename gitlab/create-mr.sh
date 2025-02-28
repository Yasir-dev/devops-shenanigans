#!/bin/bash

# USAGE INSTRUCTIONS:
# 1) Make the script executable: chmod +x create-mr.sh
# 2) Set the following variables in the script or via environment:
#    - PROJECT_ID (GitLab project ID)
#    - GITLAB_TOKEN (Personal access token with API scope)
# 3) Ensure you have jq installed (e.g., brew install jq on Mac).
# 4) Run this script from within the Git repo:
#    ./create-mr.sh
#    It will:
#      - Check for required environment settings
#      - Check if jq is installed
#      - Get the current branch and push it
#      - Prompt for merge request title
#      - Fetch available labels and allow selection
#      - Create the merge request via the GitLab API


GITLAB_URL="https://gitlab.com"
PROJECT_ID="" # Add your GitLab project ID here (e.g., 12345678) via the GitLab UI
GITLAB_TOKEN="" # Add your gitlab token here (create one in your gitlab account with api access)

function validate_environment() {
    if [[ -z "$GITLAB_TOKEN" ]]; then
        echo "❌ GitLab token not set"
        exit 1
    fi
}

function check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "❌ jq is not installed"
        echo "To install on Mac: brew install jq"
        echo "To install on Linux: sudo apt-get install jq  (Ubuntu/Debian)"
        echo "                    sudo yum install jq       (CentOS/RHEL)"
        exit 1
    fi
}

function get_current_branch() {
    local branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ -z "$branch" ]]; then
        echo "❌ No branch found. Are you inside a Git repo?"
        exit 1
    fi
    echo "$branch"
}

function push_branch() {
    local branch=$1
    if git push --set-upstream origin "$branch" &>/dev/null; then
        echo "🚀 Branch $branch pushed successfully"
    else
        echo "❌ Failed to push branch"
        exit 1
    fi
}

function get_gitlab_user() {
    local user_json=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/user")
    local user_id=$(echo "$user_json" | jq -r '.id')
    local username=$(echo "$user_json" | jq -r '.username')

    if [[ -z "$user_id" ]]; then
        echo "❌ Failed to fetch GitLab user info."
        exit 1
    fi

    echo "You are logged in as: $username" >&2  # Print to stderr so it should not be taken return value of the function
    echo "$user_id"
}

function fetch_labels() {
    local labels_json=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$PROJECT_ID/labels")
    echo "$labels_json" | jq -r '.[].name'
}

function select_labels() {
    local labels=("$@")
    local selected_labels=()

    if [[ ${#labels[@]} -eq 0 ]]; then
        echo "⚠️ No labels found." >&2
        echo ""  # Return empty string
        return
    fi

    echo "Available labels (Select multiple, type 'done' when finished):" >&2
    while true; do
        select LABEL in "${labels[@]}" "Done"; do
            if [[ "$LABEL" == "Done" ]]; then
                break 2
            elif [[ -n "$LABEL" && ! " ${selected_labels[@]} " =~ " $LABEL " ]]; then
                selected_labels+=("$LABEL")
                echo "✔ Added label: $LABEL" >&2
            else
                echo "⚠️ Invalid selection or label already chosen." >&2
            fi
            break
        done
    done

    IFS=,
    echo "${selected_labels[*]}"
}

function create_merge_request() {
    local branch=$1
    local title=$2
    local user_id=$3
    local labels=$4

    local response=$(curl --silent --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --data "source_branch=$branch" \
        --data "target_branch=main" \
        --data "title=$title" \
        --data "assignee_id=$user_id" \
        --data "labels=$labels" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests")

    local mr_url=$(echo "$response" | jq -r '.web_url')

    if [[ "$mr_url" == "null" ]]; then
        echo "❌ Failed to create Merge Request."
        echo "Response: $response"
        exit 1
    else
        echo "✅ Merge Request created successfully: $mr_url"
    fi
}

function main() {
    validate_environment
    check_jq_installed

    local branch_name=$(get_current_branch)
    push_branch "$branch_name"

    read -p "Enter Merge Request Title: " mr_title

    echo "Fetching available labels..."
    local labels=($(fetch_labels))
    local selected_labels=$(select_labels "${labels[@]}")
    echo "Selected labels: $selected_labels"

    local user_id=$(get_gitlab_user)
    create_merge_request "$branch_name" "$mr_title" "$user_id" "$selected_labels"
}

main

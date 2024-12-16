#!/usr/bin/env bash

# Written by ChatGPT
# https://chatgpt.com/share/6750c7df-6b2c-8005-a91c-1bc5b3875170

# Prompt:
# Pull any issues from Redmine that have a due date of today via API

# shellcheck disable=SC1090

# Bash3 Boilerplate Setup
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_VERSION="1.0"
readonly SCRIPT_AUTHOR="Charles N Wyble"
readonly SCRIPT_DESC="Pull Redmine issues with a due date of today and output in Markdown"

# Logging and Debugging
readonly LOG_FILE="/tmp/${SCRIPT_NAME}.log"
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
info() { echo "[INFO] [$TIMESTAMP] $*" | tee -a "$LOG_FILE"; }
error() { echo "[ERROR] [$TIMESTAMP] $*" >&2 | tee -a "$LOG_FILE"; }

# Default Exit Codes
readonly ERR_CURL_NOT_INSTALLED=10
readonly ERR_API_FAILURE=20

# Configuration
readonly REDMINE_INSTANCE="projects.knownelement.com"
readonly REDMINE_API_URL="https://${REDMINE_INSTANCE}"
readonly REDMINE_API_KEY="your_api_key_here"
readonly DATE=$(date '+%Y-%m-%d')

# Function: Usage Instructions
usage() {
    cat <<EOF
$SCRIPT_DESC

Usage:
  $SCRIPT_NAME <project_id>

Options:
  -h, --help    Display this help message.

Example:
  $SCRIPT_NAME 123
EOF
}

# Check dependencies
require_curl() {
    if ! command -v curl &>/dev/null; then
        error "curl is not installed or not in PATH. Please install it and try again."
        exit $ERR_CURL_NOT_INSTALLED
    fi
}

# Fetch issues from Redmine API
fetch_issues() {
    local project_id="$1"
    local url="${REDMINE_API_URL}/issues.json?key=${REDMINE_API_KEY}&project_id=${project_id}&due_date=${DATE}"

    info "Fetching issues with due date ${DATE} for project ID ${project_id}..."
    response=$(curl -s -w "%{http_code}" -o /tmp/redmine_response.json "$url")
    http_code=$(tail -n1 <<<"$response")

    if [[ "$http_code" -ne 200 ]]; then
        error "Failed to fetch issues from Redmine API. HTTP Code: $http_code"
        exit $ERR_API_FAILURE
    fi

    info "Issues fetched successfully. Parsing and converting to Markdown..."
    generate_markdown /tmp/redmine_response.json
}

# Generate Markdown output from JSON response
generate_markdown() {
    local json_file="$1"
    local markdown_output="/tmp/redmine_issues.md"

    echo "# Redmine Issues for ${DATE}" > "$markdown_output"
    echo "" >> "$markdown_output"

    jq -r --arg base_url "$REDMINE_API_URL" '.issues[] | "## [\(.subject)](\($base_url)/issues/\(.id))\n- **ID**: \(.id)\n- **Status**: \(.status.name)\n- **Due Date**: \(.due_date)\n\n---"' \
        "$json_file" >> "$markdown_output"

    info "Markdown output written to $markdown_output"
    cat "$markdown_output"
}

# Main Function
main() {
    local project_id="$1"

    # Ensure curl is installed
    require_curl

    # Fetch issues for the project
    fetch_issues "$project_id"
}

# Argument Parsing
if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

main "$1"


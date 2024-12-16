#!/usr/bin/env bash

# Use the Joplin CLI and create a new note for today. Let me pass in the notebook folder path. Use bash functions.

# Created by chatgpt
# https://chatgpt.com/share/6750c7df-6b2c-8005-a91c-1bc5b3875170


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
readonly SCRIPT_DESC="Create a new Daily Stakeholder Report note in Joplin"

# Logging and Debugging (from bash3boilerplate)
readonly LOG_FILE="/tmp/${SCRIPT_NAME}.log"
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
info() { echo "[INFO] [$TIMESTAMP] $*"; }
error() { echo "[ERROR] [$TIMESTAMP] $*" >&2; }

# Default Exit Codes
readonly ERR_JOPLIN_NOT_INSTALLED=10
readonly ERR_NOTEBOOK_NOT_FOUND=20

# Function: Usage Instructions
usage() {
    cat <<EOF
$SCRIPT_DESC

Usage:
  $SCRIPT_NAME <notebook_folder_path>

Example:
  $SCRIPT_NAME "Stakeholder Reports"

Options:
  -h, --help    Display this help message.
EOF
}

# Check dependencies
require_joplin() {
    if ! command -v joplin &>/dev/null; then
        error "Joplin CLI is not installed or not in PATH. Please install it and try again."
        exit $ERR_JOPLIN_NOT_INSTALLED
    fi
}

# Check if notebook exists in Joplin
notebook_exists() {
    local notebook="$1"
    if ! joplin use "$notebook" >/dev/null 2>&1; then
        error "Notebook '$notebook' does not exist. Please create it first."
        exit $ERR_NOTEBOOK_NOT_FOUND
    fi
}

# Create a new note in the specified notebook
create_note() {
    local notebook="$1"
    local today_date=$(date '+%d-%m-%Y') # Format: YYYY-MM-DD
    local title="Daily Stakeholder Report - $date"
    local content="## Daily Stakeholder Report\n\n**Date:** $date\n\n---\n\n### Key Updates\n\n- \n\n### Issues\n\n- \n\n### Next Steps\n\n- \n"

    joplin create note --title "$title" --body "$content" >/dev/null
    info "Note created successfully in notebook '$notebook'."
}

# Main Function
main() {
    local notebook_path="$1"

    # Ensure Joplin CLI is present
    require_joplin

    # Verify notebook existence
    notebook_exists "$notebook_path"

    # Create a new note
    create_note "$notebook_path"
}

# Argument Parsing
if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

main "$1"

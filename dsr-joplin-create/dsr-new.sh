#!/usr/bin/env bash

# Use the Joplin API and create a new daily stakeholder report from the DSR-Template joplin note and place it in the today notebook

# Created by chatgpt
# v1 https://chatgpt.com/share/6750c7df-6b2c-8005-a91c-1bc5b3875170
# i have learned much more about chatpgpt/prompting etc in the interim and give you 
# V2 on 12/18/2024: https://chatgpt.com/share/676337f2-7414-8005-b3cc-9cc5b6e5ec18

####################################################
# Start of script
####################################################

# Copyright (C) $(date +%Y) ReachableCEO Enterprises LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# Create a log file with the current date and time
LOG_FILE="dsr-log-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Source environment variables
ENV_FILE="../DSRVariables.env"
echo "[INFO] Sourcing environment variables from $ENV_FILE."
if [[ ! -f "$ENV_FILE" ]]; then

  echo "Error: Environment file not found at $ENV_FILE." >&2
  exit 1

fi

source "$ENV_FILE"

echo "[INFO] Environment variables sourced successfully."

# Ensure required variables are set
REQUIRED_VARS=(JOPLIN_NOTE_TITLE JOPLIN_HOST JOPLIN_PORT JOPLIN_NOTEBOOK_PATH)
for var in "${REQUIRED_VARS[@]}"; do

  if [[ -z "${!var}" ]]; then

    echo "Error: $var is not set or is null. Please check your environment file." >&2
    exit 1

  fi

done

echo "[INFO] Required variables are set."

# Function to get notebook ID by path

function get_notebook_id()

{

    local path="$1"

    echo "[INFO] Fetching notebook ID for path: $path."
    local result
    result=$(curl -sf -X GET \
        -H "Content-Type: application/json" \
        "http://$JOPLIN_HOST:$JOPLIN_PORT/folders?token=$JOPLIN_API_TOKEN" | \
        jq -r ".items[] | select(.title == \"$path\") | .id")

    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to fetch notebook ID for path $path." >&2
        exit 1

    fi

    echo "[INFO] Notebook ID for path $path: $result."
    echo "$result"

}

# Function to get a note by title, handling pagination

function get_note_by_title()

{

    echo "[INFO] Fetching note by title: $JOPLIN_NOTE_TITLE."
    local raw_response="[]"
    local page=1

    while :; do

        local response
        response=$(curl -sf -X GET \
            -H "Content-Type: application/json" \
            "http://$JOPLIN_HOST:$JOPLIN_PORT/notes?token=$JOPLIN_API_TOKEN&page=$page")

        if [[ $? -ne 0 ]]; then

            echo "Error: Failed to fetch notes from Joplin." >&2
            exit 1

        fi

        # Extract items from the response and append to raw_response
        local items
        items=$(echo "$response" | jq -c '.items')

        if [[ "$items" == "[]" ]]; then
            break
        fi

        # Merge arrays using jq
        raw_response=$(echo "$raw_response" "$items" | jq -s 'add')
        page=$((page + 1))

    done

    echo "[DEBUG] Consolidated note JSON: $raw_response" >&2

    # List all note titles for debugging
    echo "[DEBUG] Available note titles:" >&2
    echo "$raw_response" | jq -r '.[] | .title' >&2

    # Perform case-insensitive matching
    local result
    result=$(echo "$raw_response" | jq -c ".[] | select(.title | ascii_downcase == \"$(echo $JOPLIN_NOTE_TITLE | tr '[:upper:]' '[:lower:]')\")")

    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to parse JSON response." >&2
        exit 1

    fi

    if [[ -z "$result" ]]; then

        echo "Error: No note found with title $JOPLIN_NOTE_TITLE. Check if the title is correct and exists in Joplin." >&2
        exit 1

    fi

    echo "[DEBUG] Matched note JSON: $result" >&2
    echo "$result"

}

# Function to create a new note

function create_new_note()

{

    local title="$1"
    local body="$2"
    local parent_id="$3"

    echo "[INFO] Creating a new note with title: $title."
    curl -sf -X POST \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg title "$title" --arg body "$body" --arg parent_id "$parent_id" \
            '{title: $title, body: $body, parent_id: $parent_id}')" \
        "http://$JOPLIN_HOST:$JOPLIN_PORT/notes?token=$JOPLIN_API_TOKEN"

    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to create the note titled $title." >&2
        exit 1

    fi

    echo "[INFO] Note titled $title created successfully."

}

# Main function to clone the note

function clone_note_with_date()

{

    echo "[INFO] Starting the note cloning process."
    local current_date
    current_date=$(date +%Y-%m-%d)
    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to retrieve the current date." >&2
        exit 1

    fi

    echo "[INFO] Current date retrieved: $current_date."
    local new_title="DSR-$current_date"

    echo "[INFO] Fetching original note by title: $JOPLIN_NOTE_TITLE."
    local original_note
    original_note=$(get_note_by_title)
    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to fetch the note with title $JOPLIN_NOTE_TITLE." >&2
        exit 1

    fi

    echo "[INFO] Successfully fetched the original note. Extracting note ID."
    local note_id
    note_id=$(echo "$original_note" | jq -r '.id')
    if [[ $? -ne 0 || -z "$note_id" ]]; then

        echo "Error: Failed to extract note ID from the original note." >&2
        exit 1

    fi

    echo "[INFO] Fetching full details of the note with ID: $note_id."
    local full_note
    full_note=$(curl -sf -X GET \
        -H "Content-Type: application/json" \
        "http://$JOPLIN_HOST:$JOPLIN_PORT/notes/$note_id?token=$JOPLIN_API_TOKEN")

    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to fetch full details of the note with ID: $note_id." >&2
        exit 1

    fi

    echo "[DEBUG] Full note JSON: $full_note" >&2

    # Extract 'body' field or use a default value
    local body
    body=$(echo "$full_note" | jq -r 'if .body != null and .body != "" then .body else "[No content]" end')
    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to process the body from the full note details." >&2
        exit 1

    fi

    echo "[INFO] Extracted body from the full note details."

    echo "[INFO] Fetching notebook ID for path: $JOPLIN_NOTEBOOK_PATH."
    local notebook_id
    notebook_id=$(get_notebook_id "$JOPLIN_NOTEBOOK_PATH")
    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to fetch notebook ID for path $JOPLIN_NOTEBOOK_PATH." >&2
        exit 1

    fi

    if [[ -z "$notebook_id" ]]; then

        echo "Error: Notebook path $JOPLIN_NOTEBOOK_PATH does not exist." >&2
        exit 1

    fi

    echo "[INFO] Notebook ID retrieved: $notebook_id. Creating the new note."
    create_new_note "$new_title" "$body" "$notebook_id"
    if [[ $? -ne 0 ]]; then

        echo "Error: Failed to create the new note titled $new_title." >&2
        exit 1

    fi

    echo "[INFO] Successfully cloned note to $new_title in notebook $JOPLIN_NOTEBOOK_PATH."

}

# Main entry point

function main()

{

    echo "[INFO] Script execution started."
    clone_note_with_date
    echo "[INFO] Script execution completed successfully."

}

main "$@"

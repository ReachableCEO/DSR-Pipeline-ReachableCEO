#!/bin/bash

# Functions

# Search for a note by title and return its ID
search_note() {
    local title="$1"
    echo "Searching for note with title: $title"
    note_id=$(joplin search "$title" --fields id --limit 1 --json | jq -r '.[0].id')
    
    if [[ -z "$note_id" || "$note_id" == "null" ]]; then
        echo "Error: Note with title '$title' not found."
        exit 1
    fi

    echo "Found note with ID: $note_id"
    echo "$note_id"
}

# Export the note by ID to the specified directory
export_note() {
    local note_id="$1"
    local output_dir="$2"

    echo "Exporting note ID: $note_id to directory: $output_dir"
    mkdir -p "$output_dir" || {
        echo "Error: Unable to create directory $output_dir"
        exit 1
    }

    # Export the note with attachments to the specified directory
    joplin export "$note_id" --format md --output "$output_dir" || {
        echo "Error: Failed to export note ID $note_id"
        exit 1
    }

    echo "Note exported successfully to $output_dir"
}

# Main function
main() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <note-title> <output-directory>"
        exit 1
    fi

    local note_title="$1"
    local output_dir="$2"

    # Search for the note and get its ID
    local note_id
    note_id=$(search_note "$note_title")

    # Export the note
    export_note "$note_id" "$output_dir"
}

# Run the main function with all script arguments
main "$@"

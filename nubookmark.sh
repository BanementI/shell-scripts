#!/bin/bash
# Source this file to your bashrc/whatever you use.
# bk-help for list of functionality.
# Edit as you wish.
# Function to add new shortcuts
function bk() {
    pwd_output=$(pwd)

    # Check if a comment was provided
    if [ -z "$2" ]; then
        echo "Please provide a comment."
        return 1
    fi

    # Comment will be stored as $2
    comment="$2"

    # Determine the file to save shortcuts to
    if [ -z "$CASE_FILE" ]; then
        target=~/bookmark.sh
    else
        target=~/Cases/${CASE_FILE}.sh
        # Ensure the directory exists
        mkdir -p ~/Cases
        # Create the file if it doesn't exist
        touch "$target"
    fi

    # Save the bookmark with the comment
    echo "Saved as $1 with comment: $comment"

    # Append the new shortcut and comment properly
    cat >> "$target" << EOF
#$1 - $comment
function goto_$1() {
    cd "$pwd_output"
}
EOF
}

# Function to go to the saved shortcuts
function goto() {
    if [ -z "$CASE_FILE" ]; then
        target=~/bookmark.sh
    else
        target=~/Cases/${CASE_FILE}.sh
    fi

    # Check if the target file exists before trying to source it
    if [ -f "$target" ]; then
        # Source the target file to load shortcuts
        source "$target"

        # Check if the argument provided matches any of the shortcuts
        if [ -z "$1" ]; then
            echo "Please provide a shortcut name."
        else
            # Attempt to go to the provided shortcut by calling the function dynamically
            shortcut_function="goto_$1"
            if type "$shortcut_function" &> /dev/null; then
                eval "$shortcut_function"
            else
                echo "Shortcut '$1' not found."
            fi
        fi
    else
        echo "No shortcuts file found at $target"
    fi
}

# Dummy function to avoid empty goto
function dummy() {
    cd "/"
}

function bk-cases() {
    if [ -z "$1" ]
    then
        ls $HOME/Cases/ | cut -f 1 -d '.'
    fi
}

function bk-now() {
    echo $CASE_FILE
}

function bk-list() {
    if [ -e "$HOME/Cases/$1.sh" ]
    then
        grep -E "^\s*cd|^\s*#.*" "$HOME/Cases/$1.sh" | sed 's/^\s*cd\s*//; s/^\s*#//'
    else
        echo "not valid"
    fi
}

function bk-help() {
    echo 'Set environmental variable "CASE_FILE" to whatever you wish to save bookmarks to it.'
    echo 'Example: export CASE_FILE="XA-001"'
    echo " "
    echo "bk <name> <comment> = Set a bookmark with the name of \$1 and a comment \$2."
    echo "bk-cases = Show the casefiles that are available in ~/Cases."
    echo "bk-list <case> = List the bookmarks in a casefile."
    echo "bk-now = Shortcut to show the active casefile."
    echo "goto <name> = Go to the bookmark." 
}

#!/bin/bash

# Set the base directory to the current working directory
base_dir=$(pwd)

echo "Creating symbolic links for scripts in the '$base_dir' directory and its subdirectories..."

# Function to create symbolic links for all scripts in the directory
create_symlinks() {
    local dir=$1
    for file in "$dir"/*; do
        if [ -f "$file" ] && [ -x "$file" ]; then
            sudo ln -sfv "$file" "/usr/local/bin/$(basename "$file")"
        elif [ -d "$file" ]; then
            create_symlinks "$file"
        fi
    done
}

# Start the process from the base directory
create_symlinks "$base_dir"

echo "Symbolic links creation completed."

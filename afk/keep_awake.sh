#!/bin/bash

# Function to check if xdotool is installed
check_and_install_xdotool() {
    if ! command -v xdotool &> /dev/null; then
        echo "xdotool not found. Installing..."
        
        # Update package list and install xdotool
        sudo apt-get update
        sudo apt-get install -y xdotool
    else
        echo "xdotool is already installed."
    fi
}

# Function to keep the system awake
keep_awake() {
    # Move the mouse slightly every 60 seconds
    while true; do
        # Get current mouse position
        CURRENT_MOUSE_POSITION=$(xdotool getmouselocation --shell)
        
        # Parse the X and Y positions
        eval "$CURRENT_MOUSE_POSITION"
        X_ORIG=$X
        Y_ORIG=$Y
        
        # Move the mouse slightly (1 pixel to the right and then back)
        xdotool mousemove $((X_ORIG+1)) $Y_ORIG
        sleep 1
        xdotool mousemove $X_ORIG $Y_ORIG
        
        # Wait for 60 seconds
        sleep 60
    done
}

# Main script execution
check_and_install_xdotool
keep_awake

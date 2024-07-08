#!/bin/bash

# Function to install NFS packages
install_nfs() {
    sudo apt update
    sudo apt install -y nfs-common nfs-kernel-server
}

# Function to create and share a directory
setup_shared_directory() {
    local username=$1
    local shared_dir="/home/$username/shared"

    # Create the shared directory
    mkdir -p $shared_dir

    # Add the shared directory to /etc/exports
    echo "$shared_dir 127.0.0.1(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

    # Export the shared directory
    sudo exportfs -a

    # Start and enable the NFS server
    sudo systemctl start nfs-kernel-server
    sudo systemctl enable nfs-kernel-server
}

# Function to set up automatic mounting on boot
setup_fstab_entry() {
    local username=$1
    local fstab_entry="127.0.0.1:/home/$username/shared /mnt/nfs_share nfs defaults 0 0"

    # Create the mount point
    sudo mkdir -p /mnt/nfs_share

    # Add the fstab entry
    echo $fstab_entry | sudo tee -a /etc/fstab

    # Mount all filesystems mentioned in fstab
    sudo mount -a
}

# Main script execution
main() {
    # Get the current username
    local username=$(whoami)

    # Install NFS packages
    install_nfs

    # Set up the shared directory and NFS server configuration
    setup_shared_directory $username

    # Set up fstab entry for automatic mounting on boot
    setup_fstab_entry $username

    echo "NFS setup completed successfully."
    echo "Shared directory: /home/$username/shared"
    echo "Mount point: /mnt/nfs_share"
}

# Execute the main function
main


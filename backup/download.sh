#!/bin/bash

# Define variables
ip="$1"
url="http://${ip}:3000"
dir="/tmp"
filename="${dir}/bk-$(date +%Y-%m-%d).zip"
destination="$HOME"

# Download the file to /tmp
echo "Downloading file from $url..."
wget -O "$filename" "$url/$(basename $filename)"

# Check if the file was downloaded
if [[ ! -f "$filename" ]]; then
  echo "Download failed or file not found."
  exit 1
fi

# Decompress and synchronize files
echo "Decompressing and synchronizing files..."
cd "$dir"
unzip "$filename"
rsync -av --progress --remove-source-files --ignore-existing "/tmp/home/douglas/" "$destination/"

echo "Files synchronized successfully."


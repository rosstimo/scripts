#!/bin/bash

# take a file name as an argument
# get the mime type of the file and store it in a variable $mimeType
# env XDG_UTILS_DEBUG_LEVEL=2 xdg-mime query default $mimeType
# example output looks like this:
  # $env XDG_UTILS_DEBUG_LEVEL=2 xdg-mime query default image/jpeg
  # Checking /home/tim/.config/mimeapps.list
  # Checking /home/tim/.local/share/applications/mimeapps.list
  # Checking /home/tim/.local/share/applications/defaults.list and /home/tim/.local/share/applications/mimeinfo.cache
  # Checking /home/tim/.local/share/applications/defaults.list and /home/tim/.local/share/applications/mimeinfo.cache
  # Checking /home/tim/.local/share/flatpak/exports/share/applications/defaults.list and /home/tim/.local/share/flatpak/exports/share/applications/mimeinfo.cache
  # Checking /home/tim/.local/share/flatpak/exports/share/applications/defaults.list and /home/tim/.local/share/flatpak/exports/share/applications/mimeinfo.cache
  # Checking /var/lib/flatpak/exports/share/applications/defaults.list and /var/lib/flatpak/exports/share/applications/mimeinfo.cache
  # Checking /var/lib/flatpak/exports/share/applications/defaults.list and /var/lib/flatpak/exports/share/applications/mimeinfo.cache
  # Checking /usr/local/share/applications/defaults.list and /usr/local/share/applications/mimeinfo.cache
  # Checking /usr/local/share/applications/defaults.list and /usr/local/share/applications/mimeinfo.cache
  # Checking /usr/share/applications/defaults.list and /usr/share/applications/mimeinfo.cache
  # chromium.desktop
# all the lines that start with checking are the files that are being searched
# strip off checking and make a list of the files
# the last line is the system default application for the mime type
# search withing each file for the mime type and store the application name in a variable $appName
# echo $appName for each


# get the mime type of the file
# mimeType=$(file --mime-type -b $1)

mime_type='image/jpeg'

# Capture both stdout and stderr directly into a variable
command_output=$(env XDG_UTILS_DEBUG_LEVEL=2 xdg-mime query default $mime_type 2>&1)

# Filter, format the output, and replace ' and ' with new lines
formatted_output=$(echo "$command_output" | grep 'Checking' | sed -e 's/Checking //' -e 's/ and /\n/g')

# Store the lines as an array of file paths
IFS=$'\n' read -r -d '' -a file_paths <<< "$formatted_output"

# Print the array elements (for verification)
for file_path in "${file_paths[@]}"; do

  # if file exists, print the file path
  if [ -f "$file_path" ]; then
    echo "$file_path"
    # search within each file for the mime type and echo the line
    grep -i $mime_type $file_path
  fi
done


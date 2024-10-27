#!/bin/sh
# This script automates the process of mounting all locally configured rclone cloud 
# storage remotes to local directories under ~/cloud. It checks if each remote is already
# mounted and only mounts those that are not, ensuring easy access to cloud storage 
# through the local filesystem.
# Enjoy!
# Tim R

# Run the internet connectivity check script before proceeding
check_internet.sh
if [ $? -eq 0 ]; then
  # Code to run if internet is available
  for remote in $(rclone listremotes)
  do
    remote=${remote%:}
    mkdir -p "$HOME/cloud/$remote"
    if [ ! "$(findmnt -rno SOURCE,TARGET "$HOME/cloud/$remote")" ] ; then
      echo "Mounting $remote to $HOME/cloud/$remote"
      notify-send  "Mounting $remote to $HOME/cloud/$remote" &
      rclone mount "$remote": "$HOME/cloud/$remote/" --daemon
    else
      echo "$remote: $HOME/cloud/$remote"
    fi
  done
else
  # Send a notification if internet is not available
  notify-send "Internet Connectivity" "No Internet connection detected. Unable to mount cloud storage." &
fi

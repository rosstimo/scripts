#!/bin/bash

# Run the internet connectivity check script
./check_internet.sh

# Check the exit code of check_internet.sh
if [ $? -eq 0 ]; then
  # Code to run if internet is available
  echo "Running some commands that require internet..." 
  # Example: Sync files, download updates, etc.
else
  # Send a notification if internet is not available
  notify-send "Internet Connectivity" "No Internet connection detected."
fi


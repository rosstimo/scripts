#!/bin/bash

ping -c 1 -W 2 8.8.8.8 &> /dev/null

# Exit code 0 if success, 1 if failure
if [ $? -eq 0 ]; then
  exit 0  # Internet is available
else
  exit 1  # No Internet connection
fi


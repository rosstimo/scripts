#!/bin/bash

# Test connectivity with Google's public DNS server
if ping -c 1 -W 2 8.8.8.8 &> /dev/null
then
  notify-send "Internet Connectivity" "Internet is available"
else
  notify-send "Internet Connectivity" "No Internet connection"
fi


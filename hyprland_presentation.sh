#!/bin/bash

# this script looks for $HOME/.config/hypr/monitors.conf
# and overwrites it with monitors_presentation.conf

# check if the file exists
if [ -f $HOME/.config/hypr/monitors.conf ]; then
    cp -f $HOME/.config/hypr/monitors_presentation.conf $HOME/.config/hypr/monitors.conf
    # restart hyprland
    hyprctl reload
fi


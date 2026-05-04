#!/bin/bash
# take the path of an image file as an input and updates the symbolic link to the image file $HOME/.wallpaper

# if no argument is given, exit
# otherwise, check if the file exists
# if it does, update the symbolic link to the file
if [ $# -eq 0 ]; then
  echo "No arguments provided"
    exit 1
fi
# get absolute path of the file
path=$(realpath "$1")
if [ -f "$1" ]; then
    ln -sf $path $HOME/.wallpaper &&
    # cp -f "$path" $HOME/.wallpaper
    # if on xll then set the wallpaper using feh, if wayland then use hyprpaper
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        feh --bg-scale $path 
    elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        sleep 1 &&
        hyprctl hyprpaper reload ,$path && 
        exit 0
    else
        echo "Unknown session type"
        exit 1
    fi
    notify-send -t 1000 "Wallpaper set to $path"
else
  echo "File does not exist $path"
    exit 1
fi


#!/bin/bash

OPTIONS="Qt-widgets-gui\nWindowed\nWebUI\nTrigger\nWait\nSingle-instance\nNew-instance\nReplace\nShow-wizard"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "SyncthingTray")

case $CHOICE in
    "Qt-widgets-gui") syncthingtray -g ;;
    "Windowed") syncthingtray -w ;;
    "WebUI") syncthingtray --webui ;;
    "Trigger") syncthingtray --trigger ;;
    "Wait") syncthingtray --wait ;;
    "Single-instance") syncthingtray --single-instance ;;
    "New-instance") syncthingtray --new-instance ;;
    "Replace") syncthingtray --replace ;;
    "Show-wizard") syncthingtray --show-wizard ;;
    *) echo "No valid choice made" ;;
esac


#!/bin/sh
#this script will check if kmonad is running. If not, start it. if yes kill all instances.

if pgrep -x "kmonad" > /dev/null
then
    echo "kmonad is running"
    pkill kmonad
    echo "kmonad killed"
else
    echo "kmonad is not running"
    kmonad ~/.config/kmonad/tim-fw.kbd &
    echo "kmonad started"
fi

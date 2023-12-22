#!/bin/sh
#
# this script starts my win10 vm with the script win10 then configures my displays with the mirrorAllDisplays.sh script

$HOME/.local/bin/win10 &
$HOME/.local/bin/mirrorAllDisplays.sh &

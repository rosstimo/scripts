#!/bin/sh
#TODO skip if mounted, maybe unmount options
#maybe select options

status=0
#mount cloud drives
if [[ -d "/home/tim/gdrive/work/" ]] ; then
  rclone mount gdrivew: /home/tim/gdrive/work/ --daemon
else
  $status=1
fi
if [[ -d "/home/tim/gdrive/home/" ]] ; then
  rclone mount gdriveh: /home/tim/gdrive/home/ --daemon
else
  $status=1
fi
if [[ -d "/home/tim/onedrive/" ]] ; then
  rclone mount onedrive: /home/tim/onedrive --daemon
else
  $status=1
fi

exit $status

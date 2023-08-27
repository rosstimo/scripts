#!/bin/sh
#TODO skip if mounted, maybe unmount options
#maybe select options

status=0
#mount cloud drives
#if the directory already exists check to see if it mounted
#if it didn't mount then mount it
#if it did mount do nothing
#if the directory doesn't exist then create it then mount it
if [ -d "/home/tim/cloud/gdrivew/" ] ; then
  if [ ! $(findmnt -rno SOURCE,TARGET "$HOME/cloud/gdrivew") ] ; then
    rclone mount gdrivew: /home/tim/cloud/gdrivew/ --daemon
  fi
else
  mkdir -p /home/tim/cloud/gdrivew/
  rclone mount gdrivew: /home/tim/cloud/gdrivew/ --daemon
fi

if [ -d "/home/tim/cloud/gdriveh/" ] ; then
  if [ ! $(findmnt -rno SOURCE,TARGET "$HOME/cloud/gdriveh") ] ; then
    rclone mount gdriveh: /home/tim/cloud/gdriveh/ --daemon
  fi
else
  mkdir -p /home/tim/cloud/gdriveh/
  rclone mount gdriveh: /home/tim/cloud/gdriveh/ --daemon
fi

if [ -d "/home/tim/cloud/onedrive/" ] ; then
  if [ ! $(findmnt -rno SOURCE,TARGET "$HOME/onedrive") ] ; then
    rclone mount onedrive: /home/tim/cloud/onedrive --daemon
  fi

  mkdir -p /home/tim/cloud/onedrive/
  rclone mount onedrive: /home/tim/cloud/onedrive --daemon
fi

exit $status


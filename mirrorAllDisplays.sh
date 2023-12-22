#!/bin/sh
#use xrandr to get a list of displays, then loop though all displays, set them to 1920x1080 and mirror them. skip if error

# get list of displays
displays=$(xrandr | grep " connected" | awk '{print $1}')
# determine the current primary displays
primary=$(xrandr | grep " connected primary" | awk '{print $1}')
echo "Primary display is $primary"
# loop through displays
for display in $displays
do
    # set display to 1920x1080
    echo "Setting $display to 1920x1080"
    xrandr --output $display --mode 1920x1080
    # mirror display to primary in display is not Primary
    if [ "$display" = "$primary" ]; then
        continue
      else
        echo "Mirroring $display to $primary"
        xrandr --output $display --same-as $primary
    fi
done

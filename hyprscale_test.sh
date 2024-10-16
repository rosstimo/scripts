#!/bin/bash
set -x  # Enable script debugging

echo "=== Starting Test Script ==="

# Function to display usage information
usage() {
  echo "Usage: $0 [-u|-d|default|-h]"
  echo "  -u        Increase scale by 0.25"
  echo "  -d        Decrease scale by 0.25"
  echo "  default   Reset all monitors to preferred settings with scale of 1"
  echo "  -h        Display this help message"
}

# Parse command-line options
while getopts ":udh" opt; do
  case $opt in
    u) direction="up";;
    d) direction="down";;
    h) usage; exit 0;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1;;
  esac
done

shift $((OPTIND -1))  # Shift positional parameters

echo "Command-line arguments:"
echo "  direction: $direction"
echo "  positional parameter 1: $1"

echo "=== Testing hyprctl monitors command ==="
hyprctl_monitors_output=$(hyprctl monitors -j 2>&1)
hyprctl_exit_code=$?
echo "hyprctl monitors -j output:"
echo "$hyprctl_monitors_output"
echo "hyprctl exit code: $hyprctl_exit_code"

echo "=== Testing jq parsing ==="
jq_parsed_output=$(echo "$hyprctl_monitors_output" | jq '.')
jq_exit_code=$?
echo "jq parsed output:"
echo "$jq_parsed_output"
echo "jq exit code: $jq_exit_code"

if [ "$hyprctl_exit_code" -ne 0 ] || [ "$jq_exit_code" -ne 0 ]; then
  echo "Error: Failed to retrieve or parse monitor information."
  exit 1
fi

# Now simulate the original script's logic
monitors=$(echo "$hyprctl_monitors_output")

if [ "$1" = "default" ]; then
  echo "=== Resetting monitors to default ==="
  echo "$monitors" | jq -c '.[]' | while read -r monitor; do
    name=$(echo "$monitor" | jq -r '.name')
    echo "Monitor name: $name"
    echo "Executing: hyprctl keyword monitor \"$name,preferred,auto,1\""
    hyprctl keyword monitor "$name,preferred,auto,1"
    echo "Reset monitor $name to preferred settings with scale of 1."
  done
else
  if [ -z "$direction" ]; then
    echo "No valid direction specified. Use -u or -d."
    exit 1
  fi

  echo "=== Adjusting monitor scales ==="
  echo "$monitors" | jq -c '.[]' | while read -r monitor; do
    name=$(echo "$monitor" | jq -r '.name')
    current_scale=$(echo "$monitor" | jq -r '.scale')
    echo "Monitor name: $name"
    echo "Current scale: $current_scale"

    # Calculate new scale
    if [ "$direction" = "up" ]; then
      new_scale=$(echo "$current_scale + 0.25" | bc)
      if (( $(echo "$new_scale > 3.00" | bc -l) )); then
        new_scale=3.00
      fi
    elif [ "$direction" = "down" ]; then
      new_scale=$(echo "$current_scale - 0.25" | bc)
      if (( $(echo "$new_scale < 0.25" | bc -l) )); then
        new_scale=0.25
      fi
    fi
    echo "New scale: $new_scale"

    # Apply new scale setting
    echo "Executing: hyprctl keyword monitor \"$name,preferred,auto,$new_scale\""
    hyprctl keyword monitor "$name,preferred,auto,$new_scale"
    echo "Set monitor $name to new scale: $new_scale."
  done
fi

echo "=== Test Script Completed ==="


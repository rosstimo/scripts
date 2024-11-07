#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize variables
MODE=""
DRY_RUN=0
VERBOSE=0

# Function to print usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Modes (choose one):"
    echo "  -n  Normal mode (default if no mode is specified)"
    echo "  -w  Work mode"
    echo "  -p  Presentation mode"
    echo "  -1  Placeholder mode 1"
    echo "  -2  Placeholder mode 2"
    echo ""
    echo "Options:"
    echo "  -d  Dry run mode (do not execute commands)"
    echo "  -v  Verbose output"
    exit 1
}

# If no arguments are given, default to normal mode
if [ $# -eq 0 ]; then
    MODE="normal"
fi

# Process arguments using getopts
while getopts "nwp12dv" opt; do
    case "$opt" in
        n)
            MODE="normal"
            ;;
        w)
            MODE="work"
            ;;
        p)
            MODE="presentation"
            ;;
        1)
            MODE="placeholder1"
            ;;
        2)
            MODE="placeholder2"
            ;;
        d)
            DRY_RUN=1
            ;;
        v)
            VERBOSE=1
            ;;
        *)
            usage
            ;;
    esac
done

# If MODE is still empty, default to normal
if [ -z "$MODE" ]; then
    MODE="normal"
fi

# Determine session type
SESSION_TYPE=$(echo "$XDG_SESSION_TYPE" | tr '[:upper:]' '[:lower:]')

if [ "$SESSION_TYPE" == "x11" ]; then
    SESSION="x11"
elif [ "$SESSION_TYPE" == "wayland" ]; then
    # Further check if using Hyprland
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        SESSION="hyprland"
    else
        SESSION="wayland"
    fi
else
    # Default to x11 if cannot determine
    SESSION="x11"
fi

if [ $VERBOSE -eq 1 ]; then
    echo "Mode: $MODE"
    echo "Session type: $SESSION_TYPE"
    echo "Detected session: $SESSION"
fi

# Construct the script name to execute
SCRIPT_TO_RUN="$SCRIPT_DIR/${SESSION}_${MODE}.sh"

# For development/debugging, we can just echo the script name
if [ $DRY_RUN -eq 1 ]; then
    echo "Dry run: would execute $SCRIPT_TO_RUN"
else
    if [ $VERBOSE -eq 1 ]; then
        echo "Executing $SCRIPT_TO_RUN"
    fi
    # Execute the script
    if [ -x "$SCRIPT_TO_RUN" ]; then
        "$SCRIPT_TO_RUN"
    else
        echo "Error: Script $SCRIPT_TO_RUN not found or not executable"
        exit 1
    fi
fi


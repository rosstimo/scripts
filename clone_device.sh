#!/bin/bash

# ==============================================================================
# Script Name: clone_device.sh
# Description: Clones a source device to a destination device with safety checks,
#              zeroes the destination, resizes partitions and filesystems, and
#              updates the filesystem table.
# Author: ChatGPT o1-preview
# Date: 2024-10-16
# ==============================================================================

# ---------------------------
# Initialize Variables
# ---------------------------

# Set default values for flags
DRY_RUN=false
VERBOSE=false
NO_CONFIRM=false

# ---------------------------
# Function Definitions
# ---------------------------

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS] -s SOURCE -d DESTINATION"
    echo
    echo "Options:"
    echo "  -s, --source       Source device (e.g., /dev/sdb)"
    echo "  -d, --destination  Destination device (e.g., /dev/sdc)"
    echo "  -n, --dry-run      Perform a trial run without making any changes"
    echo "  -v, --verbose      Enable verbose output"
    echo "  -y, --no-confirm   Do not prompt for confirmation"
    echo "  -h, --help         Display this help message"
    echo
    echo "Example:"
    echo "  $0 -s /dev/sdb -d /dev/sdc"
    exit 1
}

# Function to print messages when verbose mode is enabled
verbose_msg() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

# Function to perform safety checks
safety_checks() {
    # Check if source and destination devices are provided
    if [ -z "$SOURCE" ] || [ -z "$DESTINATION" ]; then
        echo "Error: Source and destination devices must be specified."
        usage
    fi

    # Check if source and destination devices exist
    if [ ! -b "$SOURCE" ]; then
        echo "Error: Source device $SOURCE does not exist or is not a block device."
        exit 1
    fi
    if [ ! -b "$DESTINATION" ]; then
        echo "Error: Destination device $DESTINATION does not exist or is not a block device."
        exit 1
    fi

    # Check if source and destination are different
    if [ "$SOURCE" = "$DESTINATION" ]; then
        echo "Error: Source and destination devices must be different."
        exit 1
    fi

    # Check if the script is run with superuser privileges
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root."
        exit 1
    fi

    # Check if source is smaller than or equal to destination
    SOURCE_SIZE=$(blockdev --getsize64 "$SOURCE")
    DEST_SIZE=$(blockdev --getsize64 "$DESTINATION")

    if [ "$SOURCE_SIZE" -gt "$DEST_SIZE" ]; then
        echo "Error: Source device is larger than destination device."
        exit 1
    fi
}

# Function to display a summary and prompt for confirmation
summary() {
    echo "Summary of actions to be performed:"
    echo "-----------------------------------"
    echo "Source Device:      $SOURCE"
    echo "Destination Device: $DESTINATION"
    echo "Dry Run:            $DRY_RUN"
    echo "Verbose:            $VERBOSE"
    echo "Zero Destination:   Yes (entire device)"
    echo
    if [ "$NO_CONFIRM" = false ]; then
        read -rp "Are you sure you want to proceed? (yes/no): " CONFIRMATION
        if [ "$CONFIRMATION" != "yes" ]; then
            echo "Operation cancelled by user."
            exit 0
        fi
    fi
}

# Function to execute a command (with dry run and verbose support)
execute_cmd() {
    local CMD="$1"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] $CMD"
    else
        if [ "$VERBOSE" = true ]; then
            echo "Executing: $CMD"
        fi
        eval "$CMD"
        if [ $? -ne 0 ]; then
            echo "Error: Command failed: $CMD"
            exit 1
        fi
    fi
}

# ---------------------------
# Parse Command-Line Arguments
# ---------------------------

# Loop through all arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE="$2"
            shift 2
            ;;
        -d|--destination)
            DESTINATION="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -y|--no-confirm)
            NO_CONFIRM=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Invalid option $1"
            usage
            ;;
    esac
done

# ---------------------------
# Main Script Execution
# ---------------------------

# Perform safety checks
safety_checks

# Display summary and prompt for confirmation
summary

# Unmount source and destination devices if they are mounted
verbose_msg "Unmounting source and destination devices if mounted..."
execute_cmd "umount ${SOURCE}* 2>/dev/null || true"
execute_cmd "umount ${DESTINATION}* 2>/dev/null || true"

# Zero the entire destination device
verbose_msg "Zeroing the entire destination device..."
execute_cmd "dd if=/dev/zero of=$DESTINATION bs=1M status=progress conv=fsync"

# Flush filesystem buffers
verbose_msg "Flushing filesystem buffers..."
execute_cmd "sync"

# Clone the source device to the destination device
verbose_msg "Cloning the source device to the destination device..."
execute_cmd "dd if=$SOURCE of=$DESTINATION bs=1M status=progress conv=fsync"

# Flush filesystem buffers again
verbose_msg "Flushing filesystem buffers..."
execute_cmd "sync"

# Resize the last partition on the destination device to fill the disk
# First, get the last partition number
LAST_PARTITION=$(parted -m "$DESTINATION" print | tail -n 1 | cut -d: -f1)
if [ -z "$LAST_PARTITION" ]; then
    echo "Error: Could not determine the last partition number on $DESTINATION."
    exit 1
fi

# Resize the last partition
verbose_msg "Resizing partition $LAST_PARTITION on the destination device to fill the disk..."
execute_cmd "parted $DESTINATION resizepart $LAST_PARTITION 100% yes"

# Resize the filesystem on the last partition
LAST_PARTITION_PATH="${DESTINATION}${LAST_PARTITION}"
if [[ "$DESTINATION" =~ "/dev/loop" ]]; then
    # For loop devices, partition paths are like /dev/loopNp1
    LAST_PARTITION_PATH="${DESTINATION}p${LAST_PARTITION}"
fi

verbose_msg "Resizing the filesystem on $LAST_PARTITION_PATH..."
execute_cmd "resize2fs $LAST_PARTITION_PATH"

# Generate new UUIDs for the cloned partitions to avoid conflicts
verbose_msg "Generating new UUIDs for the cloned partitions..."
PARTITIONS=($(lsblk -ln -o NAME -x NAME "$DESTINATION" | grep -v "$(basename "$DESTINATION")"))
for PART in "${PARTITIONS[@]}"; do
    PART_PATH="/dev/$PART"
    FS_TYPE=$(blkid -o value -s TYPE "$PART_PATH")
    if [ "$FS_TYPE" = "ext2" ] || [ "$FS_TYPE" = "ext3" ] || [ "$FS_TYPE" = "ext4" ]; then
        verbose_msg "Generating new UUID for $PART_PATH..."
        execute_cmd "tune2fs -U random $PART_PATH"
    fi
done

# Create mount points
verbose_msg "Creating mount points..."
execute_cmd "mkdir -p /mnt/clone_device_mnt"
MOUNT_POINT="/mnt/clone_device_mnt"

# Mount the last partition to the mount point
verbose_msg "Mounting $LAST_PARTITION_PATH to $MOUNT_POINT..."
execute_cmd "mount $LAST_PARTITION_PATH $MOUNT_POINT"

# If there is a boot partition, mount it
BOOT_PARTITION=$(blkid -o list | grep "$DESTINATION" | grep "boot" | awk '{print $1}')
if [ -n "$BOOT_PARTITION" ]; then
    verbose_msg "Mounting boot partition $BOOT_PARTITION..."
    execute_cmd "mkdir -p $MOUNT_POINT/boot"
    execute_cmd "mount $BOOT_PARTITION $MOUNT_POINT/boot"
fi

# Generate a new fstab file
verbose_msg "Generating new fstab file..."
execute_cmd "genfstab -U $MOUNT_POINT > $MOUNT_POINT/etc/fstab"

# Unmount filesystems and clean up
verbose_msg "Unmounting filesystems and cleaning up..."
if [ -n "$BOOT_PARTITION" ]; then
    execute_cmd "umount $MOUNT_POINT/boot"
fi
execute_cmd "umount $MOUNT_POINT"
execute_cmd "rm -rf $MOUNT_POINT"

# Final sync
verbose_msg "Final filesystem sync..."
execute_cmd "sync"

echo "Device cloning completed successfully."

exit 0


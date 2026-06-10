#!/bin/bash

# Check if there are any processes using the usb hdd that's used for archiving 'cold storage' content
# if not, spin it down. If so, log which files / processes are keeping the disk spinning

LOG=/var/log/spindown-archive.log
# Use the mount point instead of the dev block, in case it is mounted as a different device
PARTITION=/mnt/ARCHIVE_HDD
LSOF_TMP=/tmp/spindown-archive-lsof.tmp

# 1. Check if the device is actually mounted.
# If it's not mounted, we don't want 'lsof' to trigger the systemd-automount unnecessarily.
if ! mountpoint -q "$PARTITION"; then
    echo "$(date): $PARTITION is not mounted, skipping spindown." >> "$LOG"
    exit 0
fi

# 2. Work out the parent disk from the mounted partition.
# In the Debian VM, this should resolve /mnt/ARCHIVE_HDD -> /dev/sdb1 -> /dev/sdb.
SOURCE=$(findmnt -rn --mountpoint "$PARTITION" -o SOURCE)
if [[ "$SOURCE" != /dev/* ]]; then
    echo "$(date): $PARTITION is backed by $SOURCE, not a block device. Skipping spindown." >> "$LOG"
    exit 0
fi

PARENT=$(lsblk -no PKNAME "$SOURCE" | head -n1)
if [[ -n "$PARENT" ]]; then
    DEVICE=/dev/$PARENT
else
    DEVICE=$SOURCE
fi

# 3. Check for active processes
if ! lsof +f -- "$PARTITION" > "$LSOF_TMP" 2>&1; then
    echo "$(date): spinning down $DEVICE" >> "$LOG"
    hdparm -y "$DEVICE" >> "$LOG" 2>&1
else
    echo "$(date): device busy, skipping" >> "$LOG"
    if [[ -s "$LSOF_TMP" ]]; then
        echo "  Active processes:" >> "$LOG"
        grep -v '^COMMAND' "$LSOF_TMP" | awk '{print "    "$1" (PID "$2") -> "$9}' >> "$LOG"
    fi
fi
rm -f "$LSOF_TMP"

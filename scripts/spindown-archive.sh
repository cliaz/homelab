#!/bin/bash

# Check if there are any processes using the usb hdd that's used for archiving 'cold storage' content
# if not, spin it down. If so, log which files / processes are keeping the disk spinning

LOG=/var/log/spindown-archive.log
#DEVICE=/dev/sdc
# Use the UUID of the disk as mounted in /etc/fstab, so this script handles the disk /dev-agnostic
DEVICE=/dev/disk/by-uuid/04db006b-3f1e-4484-8c5b-779907fbc157
#PARTITION=/dev/sdc1
# Use the mount point instead of the dev block, in case it is mounted as a different device
PARTITION=/media_ARCHIVE

# 1. Check if the device is actually mounted. 
# If it's not mounted, we don't want 'lsof' to trigger the systemd-automount unnecessarily.
if ! mountpoint -q "$PARTITION"; then
    echo "$(date): $PARTITION is not mounted, skipping spindown." >> "$LOG"
    exit 0
fi

# 2. Check for active processes
if ! /usr/sbin/lsof "$PARTITION" >/tmp/lsof.tmp 2>&1; then
  echo "$(date): spinning down $DEVICE" >> "$LOG"
  /usr/sbin/hdparm -y "$DEVICE" >> "$LOG" 2>&1
else
  echo "$(date): device busy, skipping" >> "$LOG"
  if [[ -s /tmp/lsof.tmp ]]; then
    echo "  Active processes:" >> "$LOG"
    grep -v '^COMMAND' /tmp/lsof.tmp | awk '{print "    "$1" (PID "$2") -> "$9}' >> "$LOG"
  fi
fi
rm -f /tmp/lsof.tmp

#!/bin/bash

# Check if there are any processes using the usb hdd that's used for archiving 'cold storage' content
# if not, spin it down. If so, log which files / processes are keeping the disk spinning

## Install notes
# copy the script to your home directory, e.g. /home/USER/spindown-archive.sh
# make it executable: chmod +x /home/USER/spindown-archive.sh
# Configure a cron job to run the script every 10 minutes, e.g. by creating a file /etc/cron.d/spindown-archive with the following content:

# sudo tee /etc/cron.d/spindown-archive >/dev/null <<'EOF'
# SHELL=/bin/bash
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# */10 * * * * root /home/USER/spindown-archive.sh
# EOF

# sudo chmod 644 /etc/cron.d/spindown-archive
# sudo chown root:root /etc/cron.d/spindown-archive


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

#!/usr/bin/env bash
set -Eeuo pipefail

# One-off migration: move a host built with the OLD service UIDs/GIDs onto the new contiguous IDs
# used by initial_system_setup.sh (Oct 2026). Run it ONCE, on the old host, before copying data to a new host.
#
# Overall, this script will:
# - check every service account currently has the OLD ID it expects, and abort if anything doesn't match
# - remove the pruned accounts (homeassistant, mosquitto, readarr, calibre, calibre-web)
# - rename 'huntarr' to 'neutarr' (same account, it was renamed in the compose files but never on the host)
# - change each account's UID and own-group GID to the new number
# - walk the data folders once and re-own every file from its old number to its new number
#   (files owned by a pruned account are handed to root, because the new IDs reuse those numbers)
# - flag anything in the data folders it doesn't know about, without touching it
#
# By default it only reports what it would do. Pass --apply to make the changes.
# Stop all stacks first: accounts can't be renumbered while their containers are running.
#
# Afterwards, the .env files must use the new IDs, then redeploy the stacks.

ROOT_DATA_DIR="/dockers"
# folders whose file ownership gets remapped. Each one is walked once, without crossing into other mounts
SCAN_ROOTS=(
    "/dockers"
    "/mnt/MEDIA_SSD"
    "/mnt/ARCHIVE_HDD"
    "/var/cache/plex_transcode"
)
MARKER="/var/lib/homelab-renumber-service-ids"

# accounts with no stack any more
PRUNED=(
    "homeassistant:2005"
    "mosquitto:2006"
    "readarr:2017"
    "calibre:2018"
    "calibre-web:2019"
)

# name:old_id:new_id, in ascending order of new ID. Every move is downwards and lands on a number that was
# either pruned or already vacated by an earlier line, so the order matters.
RENUMBER=(
    "adguard:2007:2005"
    "homarr:2008:2006"
    "plex:2009:2007"
    "tautulli:2010:2008"
    "radarr:2011:2009"
    "sonarr:2012:2010"
    "overseerr:2013:2011"
    "prowlarr:2014:2012"
    "qbittorrent:2015:2013"
    "notifiarr:2016:2014"
    "cloudflare:2020:2015"
    "tailscale:2021:2016"
    "neutarr:2022:2017"
    "audiobookshelf:2023:2018"
    "lazylibrarian:2024:2019"
    "unpackerr:2025:2020"
    "wyzebridge:2026:2021"
    "grafana:2027:2022"
    "loki:2028:2023"
    "prometheus:2029:2024"
)
# unchanged, listed so the 'unknown folders' check recognises them
UNCHANGED=("portainer" "watchtower" "swag" "wireguard" "gluetun")

OLD_NAME_OF_NEUTARR="huntarr"


#### Don't touch below here unless you know what you're doing

APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

if (( EUID != 0 )); then
    echo "run this command with sudo" >&2
    exit 1
fi
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

if [[ -e "$MARKER.done" ]]; then
    echo "already run on this host ($(cat "$MARKER.done")). Running it again would re-own files a second time." >&2
    exit 1
fi
if [[ -e "$MARKER.in-progress" ]]; then
    echo "a previous --apply run didn't finish ($(cat "$MARKER.in-progress"))." >&2
    echo "Don't re-run it: files already moved would be moved again. Check the state by hand." >&2
    exit 1
fi

if (( APPLY )); then
    echo "*** APPLY MODE: accounts and file ownership will be changed ***"
else
    echo "*** DRY RUN: nothing will be changed. Re-run with --apply to make the changes ***"
fi
echo

problems=0
warn() { echo "  PROBLEM: $*"; problems=$((problems + 1)); }

uid_of() { getent passwd "$1" | cut -d: -f3; }
gid_of_group() { getent group "$1" | cut -d: -f3; }

# 1. check the accounts are where we expect them
echo "== Checking accounts"
for entry in "${PRUNED[@]}"; do
    IFS=: read -r name old <<< "$entry"
    current="$(uid_of "$name" || true)"
    if [[ -z "$current" ]]; then
        echo "  $name: already gone"
    elif [[ "$current" != "$old" ]]; then
        warn "$name has UID $current, expected $old"
    else
        echo "  $name ($old): will be removed"
    fi
done

for entry in "${RENUMBER[@]}"; do
    IFS=: read -r name old new <<< "$entry"
    lookup="$name"
    if [[ "$name" == "neutarr" ]] && ! getent passwd neutarr >/dev/null && getent passwd "$OLD_NAME_OF_NEUTARR" >/dev/null; then
        lookup="$OLD_NAME_OF_NEUTARR"
    fi
    current="$(uid_of "$lookup" || true)"
    if [[ -z "$current" ]]; then
        warn "$name doesn't exist"
    elif [[ "$current" != "$old" ]]; then
        warn "$lookup has UID $current, expected $old"
    else
        group_gid="$(gid_of_group "$lookup" || true)"
        [[ "$group_gid" != "$old" ]] && warn "group $lookup has GID ${group_gid:-missing}, expected $old"
        label="$name"; [[ "$lookup" != "$name" ]] && label="$lookup -> $name"
        echo "  $label: $old -> $new"
    fi
done

for gname in media docker; do
    echo "  group $gname: $(gid_of_group "$gname" || echo missing) (unchanged)"
done

running="$(docker ps -q 2>/dev/null | wc -l | tr -d ' ' || true)"; running="${running:-0}"
if [[ "$running" != "0" ]]; then
    if (( APPLY )); then
        warn "$running containers are running. Stop all stacks first"
    else
        echo "  NOTE: $running containers are running. They must be stopped before --apply"
    fi
fi

# 2. flag things this script doesn't handle
echo
echo "== Not handled by this script (flagged only, left alone)"
known=" secrets lost+found "
for entry in "${RENUMBER[@]}" "${PRUNED[@]}"; do known+="${entry%%:*} "; done
for name in "${UNCHANGED[@]}"; do known+="$name "; done
flagged=0
for dir in "$ROOT_DATA_DIR"/* "$ROOT_DATA_DIR"/secrets/*; do
    [[ -e "$dir" ]] || continue
    name="$(basename "$dir")"
    owner="$(stat -c '%U:%G (%u:%g)' "$dir")"
    if [[ " $known " != *" $name "* ]]; then
        echo "  $dir  owner $owner  - not a known service, belongs to another project or is a leftover"
        flagged=1
    elif [[ "$owner" == UNKNOWN* || "$owner" == *:UNKNOWN* ]]; then
        echo "  $dir  owner $owner  - owned by an ID with no account"
        flagged=1
    fi
done
for entry in "${PRUNED[@]}"; do
    name="${entry%%:*}"
    for dir in "$ROOT_DATA_DIR/$name" "$ROOT_DATA_DIR/secrets/$name"; do
        [[ -e "$dir" ]] && { echo "  $dir  - pruned service: will be handed to root, delete it yourself if not needed"; flagged=1; }
    done
done
[[ -e "$ROOT_DATA_DIR/$OLD_NAME_OF_NEUTARR" ]] && { echo "  $ROOT_DATA_DIR/$OLD_NAME_OF_NEUTARR  - old folder from before the neutarr rename, compose uses $ROOT_DATA_DIR/neutarr"; flagged=1; }
(( flagged )) || echo "  nothing"

if (( problems )); then
    echo
    echo "$problems problem(s) found, nothing changed." >&2
    exit 1
fi

# 3. accounts
echo
echo "== Accounts"
if (( APPLY )); then
    echo "started $(date -Is)" > "$MARKER.in-progress"
fi
run() {
    echo "  $*"
    if (( APPLY )); then "$@"; fi
}

for entry in "${PRUNED[@]}"; do
    IFS=: read -r name old <<< "$entry"
    if getent passwd "$name" >/dev/null; then run userdel "$name"; fi
    # userdel keeps the group when other users (e.g. you) are members of it
    if (( APPLY )); then
        if getent group "$name" >/dev/null; then run groupdel "$name"; fi
    else
        echo "  groupdel $name (if still present)"
    fi
done

if ! getent passwd neutarr >/dev/null && getent passwd "$OLD_NAME_OF_NEUTARR" >/dev/null; then
    run usermod -l neutarr "$OLD_NAME_OF_NEUTARR"
    run groupmod -n neutarr "$OLD_NAME_OF_NEUTARR"
fi

for entry in "${RENUMBER[@]}"; do
    IFS=: read -r name old new <<< "$entry"
    run groupmod -g "$new" "$name"
    run usermod -u "$new" "$name"
    # services that don't use 'media' as their primary group need it pointed at their renumbered own group
    if (( APPLY )); then
        if [[ "$(id -g "$name")" == "$old" ]]; then run usermod -g "$new" "$name"; fi
    else
        echo "  usermod -g $new $name (only if its primary group is still $old)"
    fi
done

# 4. files. One pass per folder, mapping each file's ORIGINAL owner, so the chain of moves can't double up
echo
echo "== File ownership"
MAP=""
for entry in "${RENUMBER[@]}"; do IFS=: read -r _ old new <<< "$entry"; MAP+="$old:$new "; done
for entry in "${PRUNED[@]}"; do IFS=: read -r _ old <<< "$entry"; MAP+="$old:0 "; done

APPLY="$APPLY" MAP="$MAP" python3 - "${SCAN_ROOTS[@]}" <<'PY'
import os, stat, sys
from collections import Counter

apply = os.environ["APPLY"] == "1"
mapping = {int(o): int(n) for o, n in (p.split(":") for p in os.environ["MAP"].split())}
pruned = {o for o, n in mapping.items() if n == 0}
counts = Counter()
pruned_paths = []
errors = 0

def handle(path):
    global errors
    try:
        st = os.lstat(path)
    except OSError as e:
        print(f"  cannot stat {path}: {e}"); errors += 1; return
    uid = mapping.get(st.st_uid, st.st_uid)
    gid = mapping.get(st.st_gid, st.st_gid)
    if (uid, gid) == (st.st_uid, st.st_gid):
        return
    counts[f"{st.st_uid}:{st.st_gid} -> {uid}:{gid}"] += 1
    if (st.st_uid in pruned or st.st_gid in pruned) and not any(path.startswith(p + "/") for p in pruned_paths):
        pruned_paths.append(path)
    if apply:
        try:
            os.lchown(path, uid, gid)
            # chown clears setuid/setgid on files, put them back
            if not stat.S_ISLNK(st.st_mode) and st.st_mode & (stat.S_ISUID | stat.S_ISGID):
                os.chmod(path, stat.S_IMODE(st.st_mode))
        except OSError as e:
            print(f"  cannot re-own {path}: {e}"); errors += 1

for root in sys.argv[1:]:
    if not os.path.isdir(root):
        print(f"  {root}: not found, skipped"); continue
    os.listdir(root)  # triggers an automount before we read its device
    dev = os.lstat(root).st_dev
    before = sum(counts.values())
    for dirpath, dirnames, filenames in os.walk(root):
        handle(dirpath)
        keep = []
        for d in dirnames:
            full = os.path.join(dirpath, d)
            try:
                if os.lstat(full).st_dev != dev:
                    print(f"  {full}: separate mount, skipped (add it to SCAN_ROOTS if needed)"); continue
            except OSError:
                pass
            keep.append(d)
        dirnames[:] = keep
        for f in filenames:
            handle(os.path.join(dirpath, f))
    print(f"  {root}: {sum(counts.values()) - before} entries {'re-owned' if apply else 'to re-own'}")

for change, n in sorted(counts.items()):
    print(f"    {change}  x{n}")
if pruned_paths:
    print("  owned by pruned accounts, handed to root:")
    for p in pruned_paths[:50]:
        print(f"    {p}")
    if len(pruned_paths) > 50:
        print(f"    ... and {len(pruned_paths) - 50} more")
if errors:
    print(f"  {errors} error(s), see above")
    sys.exit(1)
PY

if (( APPLY )); then
    mv "$MARKER.in-progress" "$MARKER.done"
    echo "finished $(date -Is)" >> "$MARKER.done"
fi

echo
echo "== Next steps"
echo "  1. Update the UID/GID values in every stack's .env file to the new numbers above"
echo "  2. Redeploy the stacks"
echo "  3. Copy the data to the new host preserving numeric ownership (e.g. rsync -aHAX --numeric-ids)"

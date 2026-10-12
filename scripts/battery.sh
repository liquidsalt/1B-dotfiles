#!/usr/bin/env bash
# dependencies: coreutils
set -euo pipefail

# First power_supply entry that is a battery and reports a capacity.
find_device() {
    for d in /sys/class/power_supply/*; do
        [ "$(cat "$d/type" 2>/dev/null)" = Battery ] || continue
        [ -f "$d/capacity" ] || continue
        basename "$d"; return 0
    done
    return 1
}

case "${1:-}" in
    device) find_device ;;
    get)    d=$(find_device) && cat "/sys/class/power_supply/$d/capacity" ;;
    status) d=$(find_device) && cat "/sys/class/power_supply/$d/status" ;;
    *)      echo "usage: battery.sh device|get|status" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# dependencies: coreutils
set -euo pipefail

# hwmon numbering is not stable across boots, so look the node up by name
find_temp_node() {
    for n in coretemp k10temp zenpower cpu_thermal; do
        for h in /sys/class/hwmon/hwmon*; do
            [ "$(cat "$h/name" 2>/dev/null)" = "$n" ] || continue
            [ -f "$h/temp1_input" ] || continue
            echo "$h/temp1_input"; return 0
        done
    done
    return 1
}

case "${1:-}" in
    temp-path) find_temp_node ;;
    temp)      p=$(find_temp_node) && echo $(( $(cat "$p") / 1000 )) ;;
    *)         echo "usage: cpu.sh temp|temp-path" >&2; exit 2 ;;
esac

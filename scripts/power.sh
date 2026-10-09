#!/usr/bin/env bash
# dependencies: systemd (systemctl), hyprlock, uwsm, power-profiles-daemon
set -euo pipefail

case "${1:-}" in
    shutdown) systemctl poweroff ;;
    reboot)   systemctl reboot ;;
    suspend)  systemctl suspend ;;
    lock)     hyprlock ;;
    logout)   uwsm stop 2>/dev/null || hyprctl dispatch exit ;;

    profile)
        case "${2:-}" in
            get) powerprofilesctl get ;;
            set) powerprofilesctl set "${3:?usage: power.sh profile set <name>}" ;;
            *)   echo "usage: power.sh profile get|set <name>" >&2; exit 2 ;;
        esac
        ;;

    *)
        echo "usage: power.sh shutdown|reboot|suspend|lock|logout | profile get|set <name>" >&2
        exit 2
        ;;
esac

#!/usr/bin/env bash
# dependencies: systemd (systemctl), hyprlock, uwsm, power-profiles-daemon
set -euo pipefail

# Fail loudly on a missing dependency rather than halfway through.
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

case "${1:-}" in
    shutdown) need systemctl; systemctl poweroff ;;
    reboot)   need systemctl; systemctl reboot ;;
    suspend)  need systemctl; systemctl suspend ;;
    lock)     need hyprlock; hyprlock ;;
    logout)   need hyprctl; uwsm stop 2>/dev/null || hyprctl dispatch exit ;;

    profile)
        need powerprofilesctl
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

#!/usr/bin/env bash
# dependencies: bluez (bluetoothctl)
# reading is DBus; pairing needs an agent, which is bt-agent's job
set -euo pipefail

# Fail loudly on a missing dependency rather than halfway through.
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need bluetoothctl

case "${1:-}" in
    power)
        case "${2:-}" in
            on|off) bluetoothctl power "$2" ;;
            *)      echo "usage: bluetooth.sh power on|off" >&2; exit 2 ;;
        esac
        ;;

    connect)    bluetoothctl connect    "${2:?usage: bluetooth.sh connect <mac>}" ;;
    disconnect) bluetoothctl disconnect "${2:?usage: bluetooth.sh disconnect <mac>}" ;;

    # bluetoothctl --timeout exits by itself; results land on DBus, not here.
    scan)       bluetoothctl --timeout "${2:-10}" scan on >/dev/null ;;

    *)
        echo "usage: bluetooth.sh power on|off | connect <mac> | disconnect <mac> | scan <secs>" >&2
        exit 2
        ;;
esac

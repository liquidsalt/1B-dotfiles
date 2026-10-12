#!/usr/bin/env bash
# dependencies: networkmanager (nmcli)
# reading is DBus; this is only the half that changes something
set -euo pipefail

# Fail loudly on a missing dependency rather than halfway through.
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need nmcli awk

case "${1:-}" in
    radio)
        case "${2:-}" in
            on|off) nmcli radio wifi "$2" ;;
            *)      echo "usage: network.sh radio on|off" >&2; exit 2 ;;
        esac
        ;;

    # passphrase on stdin, so it stays out of the process list
    connect)
        ssid="${2:?usage: network.sh connect <ssid>}"
        pass=""
        [ -t 0 ] || IFS= read -r pass || true
        if [ -n "$pass" ]; then
            nmcli device wifi connect "$ssid" password "$pass"
        else
            nmcli connection up id "$ssid" 2>/dev/null \
                || nmcli device wifi connect "$ssid"
        fi
        ;;

    disconnect)
        iface=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')
        [ -n "$iface" ] && nmcli device disconnect "$iface"
        ;;

    *)
        echo "usage: network.sh radio on|off | connect <ssid> | disconnect" >&2
        exit 2
        ;;
esac

#!/usr/bin/env bash
# dependencies: networkmanager (nmcli)
# reading is DBus; this is only the half that changes something
set -euo pipefail

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

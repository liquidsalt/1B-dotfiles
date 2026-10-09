#!/usr/bin/env bash
# dependencies: brightnessctl
set -euo pipefail

case "${1:-}" in
    get)    brightnessctl -m | cut -d, -f4 | tr -d '%' ;;   # percent, no suffix
    set)    brightnessctl -q s "${2:?usage: brightness.sh set <value>}" ;;
    device) brightnessctl -m | cut -d, -f1 ;;
    *)      echo "usage: brightness.sh get|set <value>|device" >&2; exit 2 ;;
esac

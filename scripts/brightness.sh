#!/usr/bin/env bash
# dependencies: brightnessctl
set -euo pipefail

# Fail loudly on a missing dependency rather than halfway through.
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need brightnessctl

case "${1:-}" in
    get)    brightnessctl -m | cut -d, -f4 | tr -d '%' ;;   # percent, no suffix
    set)    brightnessctl -q s "${2:?usage: brightness.sh set <value>}" ;;
    device) brightnessctl -m | cut -d, -f1 ;;
    *)      echo "usage: brightness.sh get|set <value>|device" >&2; exit 2 ;;
esac

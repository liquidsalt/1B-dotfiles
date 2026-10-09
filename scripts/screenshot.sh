#!/usr/bin/env bash
# dependencies: grim, slurp, wl-clipboard, hyprland (hyprctl), jq
set -euo pipefail

dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/media/images")/screenshots"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$dir"

case "${1:-}" in
    select) grim -g "$(slurp)" "$file" ;;
    screen) grim -o "$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')" "$file" ;;
    all)    grim "$file" ;;
    *)      echo "usage: screenshot.sh select|screen|all" >&2; exit 2 ;;
esac

wl-copy < "$file"
echo "$file"

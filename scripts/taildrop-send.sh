#!/usr/bin/env bash
# Taildrop the Nautilus selection to one tailnet device. The menu entries under
# ~/.local/share/nautilus/scripts/Send to/ are thin wrappers around this.
# dependencies: tailscale
set -euo pipefail

target="${1:?usage: taildrop-send.sh <device>}"

say() { command -v notify-send >/dev/null && notify-send "Send to $target" "$1" || echo "$1"; }

need() {
    for c in "$@"; do
        command -v "$c" >/dev/null 2>&1 || { say "missing dependency: $c"; exit 127; }
    done
}

need tailscale

[ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ] || { say "nothing selected"; exit 0; }

files=()
while IFS= read -r f; do
    [ -n "$f" ] || continue
    # Taildrop sends files, not trees.
    [ -d "$f" ] && { say "skipped $(basename "$f"): directories cannot be sent"; continue; }
    files+=("$f")
done <<< "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"

[ "${#files[@]}" -gt 0 ] || exit 0

if err=$(tailscale file cp "${files[@]}" "$target:" 2>&1); then
    say "sent ${#files[@]}"
else
    say "failed: $(echo "$err" | tail -1)"
fi

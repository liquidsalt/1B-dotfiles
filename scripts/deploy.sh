#!/usr/bin/env bash
# dependencies: coreutils, git (only for --pull)
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

usage() { echo "usage: deploy.sh [--pull] [--dry-run]" >&2; exit 2; }

pull=0; dry=0
for a in "$@"; do
    case "$a" in
        --pull)    pull=1 ;;
        --dry-run) dry=1 ;;
        *)         usage ;;
    esac
done

[ "$pull" = 1 ] && git -C "$repo" pull --ff-only

# Copy, never symlink: the machine keeps working with the repo deleted.
copy() {
    local src="$1" dst="$2" mode="$3"
    if [ "$dry" = 1 ]; then
        printf '  %s\n' "${dst#"$HOME"/}"
        return
    fi
    install -Dm"$mode" "$src" "$dst"
}

while IFS= read -r -d '' f; do
    copy "$f" "$config/${f#"$repo"/configs/clean/}" 644
done < <(find "$repo/configs/clean" -type f -print0)

while IFS= read -r -d '' f; do
    copy "$f" "$config/scripts/$(basename "$f")" 755
done < <(find "$repo/scripts" -maxdepth 1 -name '*.sh' -print0)

# Nothing is removed, so a file deleted from the repo lingers until you delete it.

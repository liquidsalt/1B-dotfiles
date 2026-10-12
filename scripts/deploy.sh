#!/usr/bin/env bash
# dependencies: coreutils, findutils, git (only for --pull)
set -euo pipefail

# Fail loudly on a missing dependency rather than halfway through.
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need find install

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

if [ "$pull" = 1 ]; then
    command -v git >/dev/null 2>&1 || { echo "deploy.sh: --pull needs git" >&2; exit 127; }
    git -C "$repo" pull --ff-only
fi

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
done < <(find "$repo/scripts" -maxdepth 1 \( -name '*.sh' -o -name '*.py' \) -print0)

# Nothing is removed, so a file deleted from the repo lingers until you delete it.

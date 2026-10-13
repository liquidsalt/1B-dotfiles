#!/usr/bin/env bash
# Copy the configs and scripts into ~/.config from a fresh clone of the repo,
# so it runs the same from anywhere, ~/.config/scripts included.
# dependencies: coreutils, findutils, git (not for --local)
set -euo pipefail

# Fail loudly on a missing dependency rather than halfway through.
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need find install

url="${DEPLOY_REPO:-https://github.com/liquidsalt/1B-dotfiles}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

usage() { echo "usage: deploy.sh [--local] [--dry-run]" >&2; exit 2; }

# --local deploys the checkout this script sits in, uncommitted edits and all.
local_repo=0; dry=0
for a in "$@"; do
    case "$a" in
        --local)   local_repo=1 ;;
        --dry-run) dry=1 ;;
        *)         usage ;;
    esac
done

if [ "$local_repo" = 1 ]; then
    repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    [ -d "$repo/configs/clean" ] || { echo "deploy.sh: $repo is not a checkout" >&2; exit 1; }
else
    need git
    repo=$(mktemp -d "${TMPDIR:-/tmp}/deploy.XXXXXX")
    trap 'rm -rf "$repo"' EXIT
    git clone -q --depth 1 "$url" "$repo"
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

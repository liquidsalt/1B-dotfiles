#!/usr/bin/env bash
# Build the self-contained snapshot the installer restores: tar, zstd, age.
# Uploads to personal-server unless --local. Safe to run any time.
# dependencies: tar, zstd, age, findutils, openssh (upload only)
set -euo pipefail

need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}
need tar zstd age find

host="1B"
server="personal-server"
dest="/var/backup/$host"
out="${TMPDIR:-/tmp}/$host-$(date +%F).tar.zst.age"
local_only=0
[ "${1:-}" = "--local" ] && local_only=1

# What is worth carrying across a reinstall. Wallpapers are a git repo and
# projects live in forges, so neither is here.
items=(documents passwords)
[ -d "$HOME/media" ] && items+=(media)

# Helium keeps settings and extension keybinds in Preferences; everything
# large next to it is cache that rebuilds itself. Cookies and saved logins
# are sealed with the keyring's os_crypt key, so they would not decrypt on a
# new install anyway -- they are deliberately not here.
helium=".config/net.imput.helium"
hel=()
if [ -d "$HOME/$helium" ]; then
    while IFS= read -r -d '' f; do
        hel+=("${f#"$HOME"/}")
    done < <(find "$HOME/$helium" -maxdepth 2 \
        \( -name "Preferences" -o -name "Secure Preferences" \
           -o -name "Bookmarks" -o -name "Local State" -o -name "History" \) \
        -type f -print0)
    for p in "$HOME/$helium"/*/"Local Extension Settings"; do
        [ -d "$p" ] && hel+=("${p#"$HOME"/}")
    done
fi

echo "including: ${items[*]} + ${#hel[@]} helium paths"

read -rsp "backup passphrase: " pw; echo
read -rsp "again: " pw2; echo
[ "$pw" = "$pw2" ] || { echo "passphrases differ" >&2; exit 1; }

# age -p wants the passphrase on a terminal, and the pty trick takes over
# stdin -- so the archive goes to a file and age reads it as an argument.
tmp=$(mktemp "${TMPDIR:-/tmp}/bk.XXXXXX")
trap 'rm -f "$tmp"' EXIT
tar -C "$HOME" -c --exclude="media/wallpapers" -- "${items[@]}" "${hel[@]}" | zstd -T0 -3 > "$tmp"
printf '%s\n%s\n' "$pw" "$pw" |
    script -qec "age -p -o '$out' '$tmp'" /dev/null >/dev/null ||
    { echo "encryption failed" >&2; exit 1; }

ls -lh "$out"

[ "$local_only" = 1 ] && { echo "left at $out"; exit 0; }
scp -q "$out" "$server:$dest/" && echo "uploaded to $server:$dest/"

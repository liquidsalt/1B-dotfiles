#!/usr/bin/env bash
# The parts of the install that need a running system: a tailnet session and a
# GitHub login. Neither can happen in the installer's chroot, so they happen
# here, once, on the first boot. Safe to re-run.
# dependencies: tailscale, gh
set -uo pipefail

need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}
need tailscale gh

say() { printf '\n▸ %s\n' "$*"; }

say "tailnet"
if tailscale status >/dev/null 2>&1; then
    echo "  already up as $(tailscale status --json | jq -r '.Self.DNSName // "?"' 2>/dev/null)"
else
    echo "  scan the QR or open the URL to join:"
    sudo tailscale up --qr
    # The daemon sometimes registers but publishes no endpoints until it is
    # restarted; cheap to do unconditionally.
    sudo systemctl restart tailscaled
fi

say "github"
if gh auth status >/dev/null 2>&1; then
    echo "  already logged in as $(gh api user --jq .login 2>/dev/null)"
else
    gh auth login --hostname github.com --git-protocol https --web --skip-ssh-key
fi

say "done"

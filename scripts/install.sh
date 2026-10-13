#!/usr/bin/env bash
# dependencies: baked into nixos/iso.nix
set -euo pipefail

repo="${INSTALL_REPO:-github:liquidsalt/1B-dotfiles}"
host="1B"
user="commander"
server="personal-server"
disk="/dev/nvme0n1"
checkout="projects/dev/1B-dotfiles"
wallpapers="https://github.com/liquidsalt/wallpapers"
mnt="/mnt"

say() { printf '\n▸ %s\n' "$*"; }
die() { printf '\n✗ %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "run as root"

miss=
for c in disko nixos-install nixos-enter chpasswd tailscale jq curl age zstd tar script git lsblk mountpoint grep sort mktemp; do
    command -v "$c" >/dev/null 2>&1 || miss="$miss $c"
done
[ -z "$miss" ] || die "missing:$miss"

# Disk
say "target disk"
lsblk -dno NAME,MODEL,SIZE "$disk" || die "$disk not found"
read -rp "  wipe this disk? everything on it is lost [type YES]: " ok
[ "$ok" = YES ] || die "aborted"

# Passwords, all three up front so the rest is unattended
say "passwords"
read -rsp "  user ($user): " userpw; echo
read -rsp "  user, again: "        userpw2; echo
[ "$userpw" = "$userpw2" ] || die "user passwords differ"
read -rsp "  backup passphrase: " backuppw; echo
echo "  the disk passphrase is asked for by cryptsetup, twice, next."

# Partition, format, mount. disko prompts for the FDE passphrase itself.
say "partitioning"
disko --mode destroy,format,mount --flake "$repo#$host" --yes-wipe-all-disks

mountpoint -q "$mnt" || die "disko did not mount $mnt"

# Install
say "installing $host"
nixos-install --flake "$repo#$host" --no-root-password --root "$mnt"

say "setting the user password"
printf '%s:%s\n' "$user" "$userpw" | nixos-enter --root "$mnt" -- chpasswd

# Tailnet, only to reach 1O. The state is in RAM, so the logout drops the node.
say "tailnet"
echo "  scan the QR with your phone to authorise this installer:"
tailscale up --qr
tailscale status --json | jq -r '"  up as " + (.Self.DNSName // "?")'

say "fetching the backup from $server"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"; tailscale logout >/dev/null 2>&1 || true' EXIT

# MagicDNS is off here, and serve matches on Host, so pin the name to the address.
peer=$(tailscale status --json |
    jq -r --arg h "$server" '.Peer[] | select(.HostName == $h) |
        (.TailscaleIPs[0]) + " " + (.DNSName | sub("\\.$"; ""))')
[ -n "$peer" ] || die "$server is not on the tailnet"
read -r ip name <<<"$peer"
echo "  $name at $ip"

base="http://$name/backup"
get() { curl -fsSL --resolve "$name:80:$ip" "$@"; }

latest=$(get "$base/$host/" | grep -oE "$host-[0-9-]+\.tar\.zst\.age" | sort | tail -1) ||
    die "cannot reach $base/$host/"
[ -n "$latest" ] || die "no backup at $base/$host/"
echo "  $latest"
get -o "$tmp/backup.age" "$base/$host/$latest"

# The auth is only needed for that fetch, so it goes now rather than at exit.
say "leaving the tailnet"
tailscale logout

say "restoring into /home/$user"
# age wants a terminal, so it gets a pty; $user exists only inside the chroot.
printf '%s\n' "$backuppw" |
    script -qec "age -d -o '$tmp/backup.tar.zst' '$tmp/backup.age'" /dev/null >/dev/null ||
    die "wrong backup passphrase"
mkdir -p "$mnt/home/$user"
zstd -dc "$tmp/backup.tar.zst" | tar -x -C "$mnt/home/$user"

# The backup holds data; the configs come from the repo, cloned so it stays editable.
say "deploying the configs"
case "$repo" in
    github:*) url="https://github.com/${repo#github:}" ;;
    *)        url="$repo" ;;
esac
clone="/home/$user/$checkout"
git clone "$url" "$mnt$clone"
nixos-enter --root "$mnt" -- env HOME="/home/$user" "$clone/scripts/deploy.sh"

# Wallpapers are a separate public repo, kept out of the backup because they
# are large and already versioned elsewhere.
say "fetching wallpapers"
git clone -q --depth 1 "$wallpapers" "$mnt/home/$user/media/wallpapers" ||
    echo "  could not clone $wallpapers -- the picker will be empty"

nixos-enter --root "$mnt" -- chown -R "$user:users" "/home/$user"

say "done. reboot, and the tailnet node for this installer is already gone."
echo "  then run:  ~/.config/scripts/first-run.sh"
echo "  it joins the tailnet and logs in to github, which need a booted system."

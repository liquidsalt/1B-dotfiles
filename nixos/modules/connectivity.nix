{ pkgs, ... }:
{

  # Network Manager
  networking.hostName = "1B";
  users.users.commander.extraGroups = [ "networkmanager" ];

  networking.networkmanager.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Firewall
  networking.firewall = {
    enable = true;
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
  };

  # SSH
  services.openssh = {
    enable       = true;
    openFirewall = false;
  };

  # Tailscale
  services.tailscale = {
    enable = true;
    # extraUpFlags would be dead here: it only feeds tailscaled-autoconnect,
    # which does not exist without an authKeyFile. `set` runs regardless.
    extraSetFlags = [
      "--accept-dns=false"      # their resolver answers nothing for public names
      "--operator=commander"    # so taildrop works without root
    ];
  };

  # Tailnet peers. MagicDNS is off fleet-wide, so the names live here instead.
  networking.hosts = {
    "100.106.193.35" = [ "personal-server" ];
  };

  # Nautilus renders subdirectories of its scripts dir as submenus, so one thin
  # wrapper per target gives right-click -> Scripts -> Send to -> <device>.
  # Rebuilt at login because the device list is the tailnet's, not ours.
  systemd.user.services.taildrop-menu = {
    description = "Build the Nautilus \"Send to\" submenu from the tailnet";
    wantedBy    = [ "default.target" ];
    after       = [ "network-online.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "taildrop-menu" ''
        set -eu
        dir="''${XDG_DATA_HOME:-$HOME/.local/share}/nautilus/scripts/Send to"
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT

        ${pkgs.tailscale}/bin/tailscale file cp --targets 2>/dev/null |
        while read -r _ name _; do
            [ -n "$name" ] || continue
            printf '#!/bin/sh\nexec "$HOME/.config/scripts/taildrop-send.sh" %s\n' "$name" > "$tmp/$name"
            chmod 755 "$tmp/$name"
        done

        # An empty list means the tailnet was not up yet, not that the devices
        # are gone. Keep the last good menu rather than wiping it.
        if [ -n "$(ls -A "$tmp")" ]; then
            rm -rf "$dir"
            mkdir -p "$(dirname "$dir")"
            mv "$tmp" "$dir"
        fi
      '';
    };
  };

  # Taildrop: files sent from the phone land in ~/downloads with nothing to do.
  systemd.user.services.taildrop = {
    description = "Receive Taildrop files into ~/downloads";
    wantedBy    = [ "default.target" ];
    after       = [ "network-online.target" ];
    serviceConfig = {
      ExecStart  = "${pkgs.tailscale}/bin/tailscale file get --loop --conflict=rename %h/downloads";
      Restart    = "always";
      RestartSec = 10;
    };
  };

  # Bluetooth
  hardware.bluetooth = {
    enable      = true;
    powerOnBoot = true;
  };

  # Packages
  environment.systemPackages = with pkgs; [
    # Bluetooth
    bluez
    bluez-tools
  ];
}

{ pkgs, ... }:
{
  # Nessessary Firmware for Netwerking
  hardware.enableRedistributableFirmware = true;

  # Network Manager
  networking.hostName = "1B";
  users.users.commander.extraGroups = [ "networkmanager" ];

  networking.networkmanager.enable = true;

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
    extraSetFlags = [
      "--accept-dns=true"    # use MagicDNS for tailnet names
      "--operator=commander" # so taildrop works without root
    ];
  };
  services.resolved.enable = true; # Tailscale handle tailnet names while normal sites use the wifi DNS

  # Taildrop
  systemd.user.services.taildrop = {
    description = "Receive Taildrop files into ~/downloads";
    wantedBy    = [ "default.target" ];
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

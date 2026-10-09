{ pkgs, ... }:
{

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
  services.tailscale.enable = true;

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

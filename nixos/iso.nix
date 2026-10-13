{ lib, modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./modules/wifi.nix
  ];

  networking.hostName = "installer";

  # nixos-install --flake needs these, and the CD does not enable them.
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  boot.supportedFilesystems.zfs = false;   # ext4 only, and it shrinks the image

  # The CD runs wpa_supplicant standalone, with its own networks list. Hand the
  # supplicant to NetworkManager instead of switching it off: NM drives the
  # radio *through* wpa_supplicant, so disabling it leaves no wifi device at
  # all -- profiles present, radio enabled, DEVICE column empty.
  networking.wireless.userControlled.enable = lib.mkForce true;
  networking.wireless.networks = lib.mkForce { };

  services.tailscale = {
    enable = true;
    extraDaemonFlags = [ "--state=mem:" ];   # node key in RAM, so logout is final
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "install-1B" (builtins.readFile ../scripts/install.sh))
    age
    curl
    git
    gptfdisk
    jq
    tailscale
    zstd
  ];

  services.getty.helpLine = ''

    Type `sudo install-1B` to install.
  '';
}

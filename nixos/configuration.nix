{ ... }:
{
  imports = [
    ./modules/partition.nix
    ./modules/nix.nix
    ./modules/boot.nix
    ./modules/hardware.nix
    ./modules/connectivity.nix
    ./modules/wifi.nix
    ./modules/locale.nix
    ./modules/users.nix
    ./modules/dirs.nix
    ./modules/cli.nix
    ./modules/dev.nix
    ./modules/desktop.nix
    ./modules/apps.nix
  ];
}

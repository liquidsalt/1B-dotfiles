{ pkgs, ... }:
{
  users.users.commander = {
    enable       = true;
    isNormalUser = true;
    shell        = pkgs.fish;
    extraGroups = [ "wheel" ];
  };
}

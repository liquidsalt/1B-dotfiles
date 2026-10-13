{ pkgs, ... }:
{
  # Cli Applications
  environment.systemPackages = with pkgs; [
    neovim    # text editor
    yazi      # file manager

    btop      # hardware utilization and task manager
    fastfetch # distro info display

    # archives
    p7zip
    unzip
    unrar
    zstd
    age       # backup.sh encrypts the snapshot with it

    # utilities
    fd
    ripgrep
    jq
  ];

  # Shell
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = "set -g fish_greeting";  # no welcome banner

  # Shell Prompt
  programs.starship.enable = true;

  # Default Editor
  environment.variables = {
    EDITOR = "nvim";
    SUDO_EDITOR = "nvim";
  };

  # Aliases
  environment.shellAliases = {
    "cddev" = "cd ~/projects/dev";
    "cdnix" = "cd ~/projects/dev/nixos";
  };
}

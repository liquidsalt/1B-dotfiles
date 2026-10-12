{ pkgs, ... }:
{
  # Gaming
  programs.gamemode.enable  = true;
  programs.gamescope.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Heroic
    (heroic.override {
      extraPkgs = pkgs': [
        pkgs'.gamemode
        pkgs'.gamescope
      ];
    })

    kitty          # terminal emulator
    nautilus       # file manager
    loupe          # image viewer
    celluloid      # video viewer

    awww           # still wallpaper manager
    mpvpaper       # video wallpaper manager

    spotify        # music player
    vesktop        # discord + vencord
    signal-desktop # messaging

    blender        # 3d modeling
    libresprite    # pixel art editor

    obsidian       # notes
    anki           # flashcards

    # Office Suite
    libreoffice
    hunspell
    hunspellDicts.en-us
    hunspellDicts.fr-moderne
  ];

  # 
}

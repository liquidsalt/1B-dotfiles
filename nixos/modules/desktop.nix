{ lib, pkgs, ... }:
{
  # Session Manager
  services.displayManager.sddm = {
    enable         = true;
    wayland.enable = true;
  };

  # Window Manager
  programs.hyprland = {
    enable          = true;
    xwayland.enable = true;
    withUWSM        = true;
  };

  # Lockscreen
  programs.hyprlock.enable = true;

  # Packages
  environment.systemPackages = with pkgs; [
    hyprpolkitagent    # polkit agent
    grim               # screenshot capture
    slurp              # region selection
    wl-clipboard       # clipboard
    adwaita-icon-theme # gtk icons and cursor
  ];

  # Fonts
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Adwaita Sans" ];
    serif     = [ "Literata" ];
    monospace = [ "IBM Plex Mono" ];
    emoji     = [ "Twitter Color Emoji" ];
  };

  fonts.packages = with pkgs; [
    adwaita-fonts           # sans font
    literata                # serif font
    ibm-plex                # mono font

    fira-mono               # code/terminal font
    alegreya                # reading font

    # compatibility
    noto-fonts              # default fallback
    twemoji-color-font      # emojis
    noto-fonts-cjk-sans     # chinese/korean/japanese
    liberation_ttf          # times new roman and others
    nerd-fonts.symbols-only # nerd fonts icons
    material-symbols        # quickshell bar icons
  ];

  # Theme
  qt = {
    enable        = true;
    platformTheme = "gnome";       # qt apps read the dconf keys below
    style         = "adwaita-dark";
  };

  # Dconf
  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/desktop/interface" = {
      color-scheme        = "prefer-dark";
      gtk-theme           = "Adwaita-dark";
      icon-theme          = "Adwaita";
      cursor-theme        = "Adwaita";
      cursor-size         = lib.gvariant.mkInt32 24;
      font-name           = "Adwaita Sans 11";
      document-font-name  = "Literata 11";
      monospace-font-name = "IBM Plex Mono 10";
    };
  }];
}

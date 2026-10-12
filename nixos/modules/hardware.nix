{ config, lib, pkgs, ... }:
{
  # Graphics
  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = ["modesetting" "nvidia"];

  hardware.nvidia = {
    open               = true;
    modesetting.enable = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime = {
    offload.enable           = true;
    offload.enableOffloadCmd = true;

    intelBusId  = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  specialisation.docked.configuration = {
    system.nixos.tags = [ "docked" ];
    hardware.nvidia.prime = {
      offload.enable           = lib.mkForce false;
      offload.enableOffloadCmd = lib.mkForce false;

      sync.enable = lib.mkForce true;
    };

    services.udev.extraRules = ''
      KERNEL=="card*", SUBSYSTEM=="drm", ATTRS{vendor}=="0x10de", SYMLINK+="dri/nvidia-dgpu", TAG+="mutter-device-preferred-primary"
      KERNEL=="card*", SUBSYSTEM=="drm", ATTRS{vendor}=="0x8086", SYMLINK+="dri/intel-igpu"
    '';

    environment.sessionVariables = {
      AQ_DRM_DEVICES   = "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu";
      WLR_DRM_DEVICES  = "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu";
      KWIN_DRM_DEVICES = "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu";
    };
  };

  # Audio
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };
  security.rtkit.enable = true;

  # Sleep
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  services.logind.settings.Login = {
    HandleLidSwitch              = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };

  specialisation.docked.configuration = {
    systemd.targets = {
      sleep.enable        = false;
      suspend.enable      = false;
      hibernate.enable    = false;
      hybrid-sleep.enable = false;
    };
    services.logind.settings.Login.HandleLidSwitch = lib.mkForce "ignore";
  };

  # Docked Lid Screen Desactivation
  specialisation.docked.configuration = {
    boot.kernelParams = [ "video=eDP-1:d" ];
  };

  # Peripherals
  hardware.logitech.wireless.enable          = true;
  hardware.logitech.wireless.enableGraphical = true;

  # hidraw is root-only; uaccess gives the seat an ACL so headset.py can read
  # the Nari's charge without sudo. No upstream tool supports this model.
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="051e", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="051f", TAG+="uaccess"
  '';

  # Firmware updates
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;

  # Packges
  environment.systemPackages =  with pkgs; [
    solaar        # peripherals manager
    pavucontrol   # audio manager
    brightnessctl # brightness manager
    xrandr        # x11 monitor manager
  ];
}

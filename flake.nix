{
  description = "Type B";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows        = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs";   # or the lock pulls a second nixpkgs
    };
  };

  outputs = { self, nixpkgs, disko, helium, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      # disko looks here first; without it the installer relies on the
      # fallback into nixosConfigurations.<host>.config.disko.devices.
      # The whole module, not its .disko.devices: disko reads cfg.disko.devices
      # off what it finds here.
      diskoConfigurations."1B" = import ./nixos/modules/partition.nix { };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/iso.nix
          # Baked in: matches the lock, and needs no network to partition.
          { environment.systemPackages = [ disko.packages.${system}.disko ]; }
        ];
      };

      packages.${system}.iso =
        self.nixosConfigurations.installer.config.system.build.isoImage;

      nixosConfigurations."1B" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          {
            nixpkgs.overlays = [
              (final: prev: {
                unstable = import inputs.nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;       # separate instance, own config
                };
                helium = helium.packages.${system}.default;
              })
            ];
          }
          ./nixos/configuration.nix
        ];
      };
    };
}

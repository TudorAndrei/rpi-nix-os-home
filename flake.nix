{
  description = "Raspberry Pi 4 Model B living-room HTPC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, nixos-hardware, ... }:
    let
      system = "aarch64-linux";

      mkLivingRoom =
        hardwareModules: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs; };

          modules = hardwareModules ++ [ ./configuration.nix ] ++ extraModules;
        };

      raspberryPiModules = [
        nixos-hardware.nixosModules.raspberry-pi-4
        ./hardware.nix
      ];

      livingRoom = mkLivingRoom raspberryPiModules [ ];
      livingRoomImage = mkLivingRoom raspberryPiModules [ ./sd-image.nix ];
      livingRoomQemu = mkLivingRoom [ ] [ ./qemu.nix ];
    in
    {
      nixosConfigurations = {
        living-room = livingRoom;
        living-room-image = livingRoomImage;
        living-room-qemu = livingRoomQemu;
      };

      packages.${system} = {
        default = livingRoomImage.config.system.build.sdImage;
        sd-image = livingRoomImage.config.system.build.sdImage;
        qemu-bundle = livingRoomQemu.config.system.build.qemuBundle;
      };
    };
}

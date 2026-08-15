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
        extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs; };

          modules = [
            nixos-hardware.nixosModules.raspberry-pi-4
            ./configuration.nix
          ] ++ extraModules;
        };

      livingRoom = mkLivingRoom [ ];
      livingRoomImage = mkLivingRoom [ ./sd-image.nix ];
    in
    {
      nixosConfigurations = {
        living-room = livingRoom;
        living-room-image = livingRoomImage;
      };

      packages.${system} = {
        default = livingRoomImage.config.system.build.sdImage;
        sd-image = livingRoomImage.config.system.build.sdImage;
      };
    };
}

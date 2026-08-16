{
  description = "Raspberry Pi OS living-room HTPC home configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "aarch64-linux";
      username = "user";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      homeConfiguration = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = { inherit inputs; };

        modules = [
          ./home.nix
          {
            home = {
              inherit username;
              homeDirectory = "/home/${username}";
            };
          }
        ];
      };
    in
    {
      homeConfigurations.${username} = homeConfiguration;

      packages.${system} = {
        home-manager = homeConfiguration.config.programs.home-manager.package;
        plasma-bigscreen =
          pkgs.kdePackages.callPackage ./packages/plasma-bigscreen.nix { };
      };

      checks.${system}.home = homeConfiguration.activationPackage;
      formatter.${system} = pkgs.nixfmt-tree;
    };
}

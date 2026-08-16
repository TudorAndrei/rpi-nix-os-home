{ pkgs, ... }:

let
  plasmaBigscreen = pkgs.kdePackages.callPackage ../packages/plasma-bigscreen.nix { };
in
{
  home.packages = with pkgs; [
    plasmaBigscreen
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.konsole
    kdePackages.plasma-nm
    kdePackages.systemsettings
  ];
}

{ pkgs, ... }:

let
  plasmaBigscreen = pkgs.kdePackages.callPackage ./packages/plasma-bigscreen.nix { };
in
{
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.displayManager = {
    defaultSession = "plasma-bigscreen-wayland";
    sessionPackages = [ plasmaBigscreen ];

    autoLogin = {
      enable = true;
      user = "htpc";
    };

    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    plasmaBigscreen
    kdePackages.bluedevil
    kdePackages.kate
    kdePackages.konsole
    kdePackages.plasma-nm
    kdePackages.systemsettings
  ];

  programs.dconf.enable = true;
  security.polkit.enable = true;
  services.udisks2.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };
}

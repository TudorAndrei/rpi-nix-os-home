{ pkgs, ... }:

{
  imports = [
    ./home/bigscreen.nix
    ./home/gaming.nix
    ./home/media.nix
  ];

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };

  home = {
    stateVersion = "26.05";

    packages = with pkgs; [
      git
      helix
      htop
      pciutils
      usbutils
    ];

    sessionVariables = {
      TZ = "Europe/Bucharest";
      LANG = "en_US.UTF-8";
      LC_ADDRESS = "ro_RO.UTF-8";
      LC_IDENTIFICATION = "ro_RO.UTF-8";
      LC_MEASUREMENT = "ro_RO.UTF-8";
      LC_MONETARY = "ro_RO.UTF-8";
      LC_NAME = "ro_RO.UTF-8";
      LC_NUMERIC = "ro_RO.UTF-8";
      LC_PAPER = "ro_RO.UTF-8";
      LC_TELEPHONE = "ro_RO.UTF-8";
      LC_TIME = "ro_RO.UTF-8";
    };
  };

  programs = {
    bash.enable = true;
    home-manager.enable = true;
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}

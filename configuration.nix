{ pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./bigscreen.nix
    ./media.nix
    ./gaming.nix
    ./networking.nix
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  users.users.htpc = {
    isNormalUser = true;
    description = "Living-room HTPC";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "render"
      "video"
      "wheel"
    ];

    openssh.authorizedKeys.keyFiles = [ ./keys/rpi.pub ];
  };

  # The SSH key is the authentication control for this appliance.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    helix
    htop
    pciutils
    usbutils
  ];

  time.timeZone = "Europe/Bucharest";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  system.stateVersion = "26.05";
}

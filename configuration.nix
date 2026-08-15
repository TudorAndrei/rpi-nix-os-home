{ pkgs, ... }:

{
  imports = [
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
    initialHashedPassword = "$6$rpihtpc$Ndk7yilXAbfYhj6p.3QrJwtR0wJfsd.Kqqimh.t3UHNBHxHzd4qOD7Pe/r3kkux/PE2bdStMbIHrPjxB3JMsh1";
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
  i18n.extraLocaleSettings = {
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
  console.keyMap = "us";

  system.stateVersion = "26.05";
}

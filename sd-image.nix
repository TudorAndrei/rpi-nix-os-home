{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];

  image.baseName = "living-room-rpi4-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

  sdImage = {
    compressImage = true;
    expandOnBoot = true;

    # Nixpkgs marks this partition as FAT32. A 512 MiB partition makes
    # mkfs.vfat select FAT32 instead of FAT16, which the Pi 4 firmware rejects.
    firmwareSize = 512;
  };

  # The image is an appliance image, not an installation environment.
  documentation.enable = lib.mkDefault false;
}

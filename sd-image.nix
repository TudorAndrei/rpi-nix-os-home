{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];

  sdImage = {
    compressImage = true;
    expandOnBoot = true;
    imageName = "living-room-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.img";
    rootPartitionSize = 8192;
  };

  # The image is an appliance image, not an installation environment.
  documentation.enable = lib.mkDefault false;
}

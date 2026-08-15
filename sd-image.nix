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
  };

  # The image is an appliance image, not an installation environment.
  documentation.enable = lib.mkDefault false;
}

{ lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [
      "dmask=0022"
      "fmask=0022"
    ];
  };

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    configurationLimit = 8;
  };

  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;

    raspberry-pi.firmware = {
      enable = true;
      uboot.enable = true;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
}

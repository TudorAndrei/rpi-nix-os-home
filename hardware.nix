{ lib, pkgs, ... }:

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

  # Use the stable Raspberry Pi 4 kernel. It keeps the Pi-specific media and
  # display support on the Linux 6.12 long-term support series.
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  # The generic ARM image adds modules for many unrelated boards. Some of
  # those driver names are built into the Raspberry Pi kernel and cannot be
  # copied as modules. Keep the initrd list specific to Raspberry Pi 4.
  boot.initrd.availableKernelModules = lib.mkForce [
    "usb-storage"
    "usbhid"
    "vc4"
    "pcie-brcmstb"
    "reset-raspberrypi"
  ];

  boot.supportedFilesystems = lib.mkForce [
    "ext4"
    "vfat"
    "cifs"
    "nfs"
  ];

  hardware.raspberry-pi."4".bluetooth.enable = false;

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

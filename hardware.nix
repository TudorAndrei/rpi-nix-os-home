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

  # The generic ARM image adds modules for many unrelated boards. Some of
  # those driver names are built into the Raspberry Pi kernel and cannot be
  # copied as modules. Keep the initrd list specific to Raspberry Pi 5.
  boot.initrd.availableKernelModules = lib.mkForce [
    "usb-storage"
    "usbhid"
    "vc4"
    "nvme"
    "pcie-brcmstb"
    "clk-rp1"
    "rp1"
  ];

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

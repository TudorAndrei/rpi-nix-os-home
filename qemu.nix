{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  qemuRootFileSystem = pkgs.callPackage "${modulesPath}/../lib/make-ext4-fs.nix" {
    storePaths = [ config.system.build.toplevel ];
    compressImage = false;
    populateImageCommands = "";
    volumeLabel = "nixos";
  };

  qemuDisk = pkgs.runCommand "living-room-qemu-disk" {
    nativeBuildInputs = [ pkgs.qemu-utils ];
  } ''
    mkdir -p "$out"
    qemu-img convert -f raw -O qcow2 ${qemuRootFileSystem} "$out/living-room-qemu.qcow2"
  '';

  kernelFile = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
  initrdFile = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
  kernelCommandLine = lib.concatStringsSep " " (
    [ "init=${config.system.build.toplevel}/init" ] ++ config.boot.kernelParams
  );
in
{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot = {
    growPartition = false;
    kernelPackages = pkgs.linuxPackages;

    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
    ];

    kernelParams = [
      "root=/dev/disk/by-label/nixos"
      "rw"
      "console=ttyAMA0,115200n8"
      "console=tty0"
    ];

    loader.grub.enable = lib.mkForce false;
  };

  hardware.graphics.enable = true;
  services.qemuGuest.enable = true;

  system.build = {
    inherit qemuDisk;

    qemuBundle = pkgs.runCommand "living-room-qemu-bundle" { } ''
      mkdir -p "$out"
      ln -s ${qemuDisk}/living-room-qemu.qcow2 "$out/disk.qcow2"
      ln -s ${kernelFile} "$out/Image"
      ln -s ${initrdFile} "$out/initrd"
      printf '%s\n' ${lib.escapeShellArg kernelCommandLine} > "$out/cmdline"
    '';
  };
}

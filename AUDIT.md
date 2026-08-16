# Audit report: Raspberry Pi 4 HTPC boot failure

Date: 2026-08-16
Scope: full repository, flashed image `build/rpi4-htpc.img`, pinned sources in `flake.lock`
(nixpkgs `0e251e24`, nixos-hardware `2dda1929`).

## Confirmed findings

**F1 — The failed image has a kernel that does not match the device trees.**
The image root partition holds `extlinux.conf` with kernel `linux-rpi-6.12.75-1+rpt1`.
The firmware partition holds device trees from `raspberrypifw` version `1.20260521`.
That firmware release belongs to the Linux 6.18 vendor series. The vendor kernel and
the vendor device tree must come from the same release series. Here they are two
kernel series apart.
Evidence: `extlinux.conf` in image partition 2
(`LINUX ../nixos/dc8x5xjjrikgmi7jgxbhv5vhplqsvd2c-linux-rpi-6.12.75-1+rpt1-Image`);
nixpkgs `0e251e24` (`flake.lock:29`) has `raspberrypifw = 1.20260521`; the removed
line in `hardware.nix` (old lines 25-27) forced `pkgs.linuxPackages_rpi4` = 6.12.75.

**F2 — The firmware partition content is correct and complete.**
The partition contains `bcm2711-rpi-4-b.dtb`, the `overlays` directory with
`vc4-kms-v3d.dtbo`, `bootcode.bin`, `start4.elf`, `fixup4.dat`, `u-boot.bin`
(U-Boot 2026.07), and one `config.txt`. The `config.txt` sets `arm_64bit=1`,
`kernel=u-boot.bin`, `enable_uart=1`, `dtoverlay=vc4-kms-v3d`, and
`disable_fw_kms_setup=1`. This is the intended full-KMS configuration for the
vendor kernel.

**F3 — The two firmware-population modules do not conflict.**
The pinned nixos-hardware module `raspberry-pi/common/firmware.nix` sets
`sdImage.populateFirmwareCommands` with `lib.mkForce`. This fully replaces the
population commands from `sd-image-aarch64.nix`. The image confirms this: only one
`config.txt` exists, and it is the nixos-hardware version.

**F4 — The missing `FDTDIR` line is intentional and correct.**
`extlinux.conf` has no `FDT` or `FDTDIR` line. The nixos-hardware firmware module
sets `boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = false` when
U-Boot chainload is on. U-Boot then keeps the device tree that the GPU firmware
patched. The kernel thus receives the `vc4-kms-v3d` overlay and the firmware fixups.
This is the correct design for the vendor kernel.

**F5 — The missing `armstub8-gic.bin` is not the fault.**
The firmware partition has no arm stub and no `enable_gic=1`. On the BCM2711,
`enable_gic` has the default value 1, and the firmware supplies a built-in stub.
The physical test confirms this path: U-Boot started and loaded the kernel.

**F6 — The `lib.mkForce` initrd module list is safe.**
`hardware.nix:28-34` forces `[usb-storage usbhid vc4 pcie-brcmstb reset-raspberrypi]`.
This is exactly the union of the lists in the pinned nixos-hardware modules
(`raspberry-pi/common/default.nix` and `raspberry-pi/4/default.nix`). The SD-card
controller drivers are built into the `bcm2711_defconfig` kernel. The initrd does
not need them as modules. The force only removes the optional `genet` entry, and
that entry applies only when `boot.initrd.network.enable` is true. It is not true here.

**F7 — The QEMU test cannot see this class of fault.**
`scripts/test-image-qemu.sh:82-91` gives `u-boot.bin` and a bare DTB directly to
QEMU. QEMU does not run `start4.elf`. So the test does not apply `config.txt`, the
`vc4-kms-v3d` overlay, or the firmware fixups. The test stops at "Starting
kernel ...". It proves the extlinux chain only. It cannot prove display, network,
or user space on the physical Pi.

**F8 — Serial console evidence is already available.**
`config.txt` has `enable_uart=1`. The kernel command line has
`console=ttyS0,115200n8 console=ttyAMA0,115200n8 console=tty0` and `loglevel=7`.
A USB serial adapter on GPIO 14/15 shows the full kernel log on the physical Pi.
No configuration change is necessary for this.

**F9 — The active build uses the aligned kernel.**
The build compiles `linux-rpi` 6.18.39 from nixos-hardware tag `stable_20260724`,
series 6.18. The pinned firmware is `1.20260521`, series 6.18. These match. The
`vc4` module loads in the initrd, so the display hand-over happens in stage 1 with
a matched kernel and device tree.

## Ranked hypotheses

**H1 (most probable): Kernel and device-tree mismatch broke the boot after the
early messages.** The GPU firmware showed the early kernel messages through the
simple framebuffer. Then, in the initrd, the 6.12.75 `vc4` driver received a
6.18-series device tree. The driver removed the simple framebuffer and could not
start the display again. The result is "No signal". The same mismatch, or a related
stage-1 fault, stopped the boot before user space. That explains the dead network
and the absent SSH. The Ethernet lamps show only a physical link from the PHY, not
a running system.

**H2: The boot stopped in stage 1 for a different reason (root mount or a panic).**
The symptoms also fit a stage-1 hang that is independent of the display. Only a
serial log can separate H2 from H1.

**H3 (least probable): Two independent faults, one in HDMI and one in the network.**
This needs two separate failures at the same time. Treat this as unlikely until the
serial log shows a running user space.

## Smallest recommended change

Change no file now. The correct single-variable change is already active: the
removal of `boot.kernelPackages = pkgs.linuxPackages_rpi4` from `hardware.nix`.
That change aligns the kernel (6.18.39) with the device trees (1.20260521). Let the
build complete. Then verify, flash, and test. Do not add HDMI options, initrd SSH,
or other changes in the same step. Hold `hdmi_force_hotplug` (through
`hardware.raspberry-pi.configtxt.settings.all`) as the next single change, only if
the new image boots to SSH but the TV stays dark.

## Verification commands

All commands run on macOS. They are read-only for the image. Run them only after
the build ends.

Verify the checksum and the FAT32 header:

```bash
scripts/verify-image.sh build
```

Confirm that the new image contains the 6.18.39 kernel:

```bash
zstd -d --stdout build/living-room-rpi4-*.img.zst > /tmp/rpi-new.img
docker run --rm -v /tmp/rpi-new.img:/img.img:ro alpine:latest sh -c \
  "apk add -q e2fsprogs-extra; debugfs -R 'cat /boot/extlinux/extlinux.conf' /img.img?offset=545259520 2>/dev/null"
```

The `LINUX` line must contain `linux-rpi-6.18.39`. The offset value 545259520 is
sector 1064960 × 512. Confirm the sector number first with `fdisk /tmp/rpi-new.img`
if the partition layout changed.

Confirm the firmware partition content:

```bash
dd if=/tmp/rpi-new.img of=/tmp/fw.img bs=1048576 skip=8 count=512
hdiutil attach -readonly -mountpoint /tmp/fwmount /tmp/fw.img
cat /tmp/fwmount/config.txt
ls /tmp/fwmount/bcm2711-rpi-4-b.dtb /tmp/fwmount/u-boot.bin /tmp/fwmount/overlays/vc4-kms-v3d.dtbo
hdiutil detach /tmp/fwmount
```

Run the U-Boot chain test:

```bash
scripts/test-image-qemu.sh
```

## Physical Pi test procedure

1. Wait for the build to end. Do not stop the build container.
2. Run the verification commands above.
3. Run `scripts/prepare-image-for-imager.sh`. Flash `build/rpi4-htpc.img` with
   Raspberry Pi Imager. Use **Use custom**. Do not select the `.img.zst` file.
4. Connect the Ethernet cable and the HDMI cable. Turn on the TV first. Then apply
   power to the Pi.
5. Wait five minutes. The first boot expands the root partition and starts the
   desktop.
6. Test SSH: `ssh -i ~/.ssh/rpi htpc@living-room.local`. If mDNS fails, examine the
   DHCP lease list in the router.
7. If the boot fails again, collect evidence before any new change:
   - Best evidence: connect a USB serial adapter (3.3 V) to GPIO 14 (TXD), GPIO 15
     (RXD), and ground. Use 115200 baud. Record the full kernel log.
   - Alternative evidence: put the SD card back in the Mac. Find the device with
     `diskutil list`. Copy the root partition:
     `sudo dd if=/dev/rdiskNs2 of=/tmp/sdroot.img bs=1m`. Then examine it:

     ```bash
     docker run --rm -v /tmp/sdroot.img:/img.img:ro alpine:latest sh -c \
       "apk add -q e2fsprogs-extra; debugfs -R 'ls -l /var/log/journal' /img.img 2>/dev/null"
     ```

     Journal files present = user space started, and the fault is display or
     network only. Journal files absent = the boot stopped in stage 1 or stage 2.

## Risks and rollback procedure

- **Flash risk.** The flash operation erases the SD card. This is the intended
  effect. No other data is at risk.
- **Rollback of the image.** Keep the current `build/rpi4-htpc.img` and the current
  `.img.zst` file before you overwrite them. To roll back, flash the kept image
  again.
- **Rollback of the configuration.** The only local change is uncommitted
  (`hardware.nix`, kernel force removal). `git checkout -- hardware.nix` restores
  the old state. Do not commit until the physical test passes.
- **Build risk.** The kernel build is long because no binary cache entry exists for
  the nixos-hardware kernel. Do not stop the container. The Docker volume
  `rpi-nix-store` keeps the compiled kernel for later builds.
- **Residual risk.** The kernel alignment is the most probable fix, but it is not
  proven. If the new image fails, the serial log from the test procedure separates
  a display fault from a boot fault. Make only one change per test cycle after
  that.

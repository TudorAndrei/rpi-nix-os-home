# Raspberry Pi 4 Model B Living-Room HTPC

This repository contains a declarative NixOS configuration for a Raspberry Pi 4 Model B. The Pi starts a TV interface and provides media, music, and game-streaming applications.

## Current scope

The configuration provides:

- NixOS unstable for `aarch64-linux`
- The Raspberry Pi 4 module from `nixos-hardware`
- KDE Plasma 6 for maintenance
- Plasma Bigscreen as the automatic Wayland session
- Automatic login for the `htpc` user
- PipeWire audio through HDMI
- USB game-controller support
- Moonlight for a Sunshine host
- Kodi for local and network media
- Chromium launchers for Stremio Web and Spotify Web
- NetworkManager, SSH, and `.local` host discovery

## Important limits

Plasma Bigscreen is new again and can still have defects. The current `nixos-unstable` branch does not contain its package. This repository includes a pinned package definition from the Nixpkgs review work. Remove the local package when Bigscreen reaches `nixos-unstable`.

Stremio and Spotify do not have first-class ARM64 Linux desktop applications. The first version uses their web applications. Browser DRM support on ARM64 Linux can limit Spotify playback. A Spotify Connect service and a local Stremio service are later tasks.

Controller input works in Plasma Bigscreen and Moonlight. Web pages can still need a keyboard, a mouse, or a browser extension.

## Repository layout

```text
.
├── flake.nix
├── configuration.nix
├── hardware.nix
├── bigscreen.nix
├── media.nix
├── gaming.nix
├── networking.nix
├── sd-image.nix
├── keys
│   └── rpi.pub
├── scripts
│   ├── build-image.sh
│   ├── build-image-docker.sh
│   ├── build-image-github.sh
│   ├── test-image-qemu.sh
│   └── verify-image.sh
└── packages
    └── plasma-bigscreen.nix
```

## Values to review

Before the first deployment, review these values:

- Host name: `living-room`
- User name: `htpc`
- Initial local password: `raspberry`
- Time zone: `Europe/Bucharest`
- Regional formats: Romanian (`ro_RO.UTF-8`)
- Keyboard layout: `us`
- Root partition label: `NIXOS_SD`
- Firmware partition label: `FIRMWARE`
- Root partition: automatically expands to use the SD card on first boot

The image contains the public key from `keys/rpi.pub`. Its current fingerprint is:

```text
SHA256:YwIGjeDU+PibuMUBj9mDpVPXSweGb2ZsoHIaGxOk9Ss
```

The matching private key is expected at `~/.ssh/rpi` on the administration computer. SSH password login and root login are disabled. The initial password is only for local access. The `htpc` user can use `sudo` without a password after SSH key authentication.

## Build the image

This repository has a manual GitHub Actions workflow. It uses a native ARM64 Linux runner, creates `flake.lock`, builds the complete image, and uploads the compressed image as a private workflow artifact.

Commit and push the files. Then run:

```bash
scripts/build-image-github.sh
```

The `build` directory will contain:

- A compressed `.img.zst` SD image
- `flake.lock`
- `SHA256SUMS`

Copy the generated `flake.lock` file to the repository and commit it. Later builds will then use the same inputs.

## Local Docker build

Docker Desktop or OrbStack can build the image locally on macOS. On Apple Silicon, the build uses a native ARM64 Linux container. The script keeps the Nix store in a Docker volume, so later builds can reuse downloaded and built files.

Give the Docker engine at least 40 GB of disk space. Stage or commit all Nix files, and then run:

```bash
git add .
scripts/build-image-docker.sh
```

To inspect the Docker command without a build, run:

```bash
scripts/build-image-docker.sh --dry-run
```

To get machine-readable final output, run:

```bash
scripts/build-image-docker.sh --output json
```

To build directly on an AArch64 Linux system that has Nix, run:

```bash
scripts/build-image.sh
```

Verify a local build with:

```bash
scripts/verify-image.sh build
```

Test the Raspberry Pi 4 boot chain in QEMU before writing the SD card:

```bash
scripts/test-image-qemu.sh
```

The QEMU test needs 16 GiB of temporary free space. It removes the temporary
raw image when the test ends. QEMU does not emulate all Raspberry Pi hardware,
so test the final image once on the physical Pi.

The first image build compiles a Raspberry Pi kernel and Plasma Bigscreen if a binary substitute is not available. The cloud build can take a long time.

## Flash and boot

Use Raspberry Pi Imager or Balena Etcher to flash the `.img.zst` file. You do not have to install NixOS first. The image already contains this complete configuration.

Connect Ethernet before the first boot. After the Pi starts, connect with:

```bash
ssh -i ~/.ssh/rpi htpc@living-room.local
```

The Pi automatically logs the `htpc` user into Plasma Bigscreen on the attached TV.

## Controller connection

Bluetooth support is disabled. Connect the controller to the Raspberry Pi with a USB cable or a supported USB wireless adapter.

## Moonlight

Install Sunshine on the gaming PC. Connect both devices to the same wired network. Start Moonlight on the Pi, add the gaming PC, and complete the PIN process in Sunshine.

Start with 1080p at 60 frames per second. Check latency and dropped frames before you increase the resolution or bit rate.

## Update and rollback

Update the lock file and build a new generation on the Pi:

```bash
nix flake update
sudo nixos-rebuild switch --flake .#living-room
```

If the new generation has a problem, select an older generation in the boot menu. You can also run:

```bash
sudo nixos-rebuild switch --rollback
```

## Primary sources

- [NixOS manual](https://nixos.org/manual/nixos/unstable/)
- [NixOS Raspberry Pi installation guide](https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi.html)
- [`nixos-hardware` Raspberry Pi 4 module](https://github.com/NixOS/nixos-hardware/tree/master/raspberry-pi/4)
- [Plasma Bigscreen](https://plasma-bigscreen.org/)
- [Moonlight Qt](https://github.com/moonlight-stream/moonlight-qt)
- [Sunshine](https://github.com/LizardByte/Sunshine)

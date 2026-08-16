# Raspberry Pi OS Living-Room HTPC

This repository manages the living-room user environment on 64-bit Raspberry Pi OS. Raspberry Pi OS owns the kernel, firmware, boot process, display drivers, and system services. A pinned Home Manager flake owns the user applications, launchers, shell tools, and Plasma Bigscreen package.

The configuration does not use ad hoc Nix package installation commands. All Nix packages come from `flake.nix` and `home.nix`.

## Managed configuration

Home Manager provides:

- Plasma Bigscreen and supporting KDE applications
- Moonlight
- Kodi
- Chromium
- Stremio Web and Spotify Web launchers
- MPV and VLC
- Git, Helix, htop, PCI tools, USB tools, and controller test tools
- Romanian regional formats and the Europe/Bucharest time zone
- Generic Linux graphics integration

Raspberry Pi OS provides:

- Raspberry Pi kernel and firmware
- HDMI and GPU drivers
- LightDM
- PipeWire and WirePlumber
- SSH
- Ethernet and DHCP
- systemd, D-Bus, PolicyKit, and UDisks

## Required system

- Raspberry Pi 4 Model B
- 64-bit Raspberry Pi OS
- User name `user`
- Ethernet connection
- Internet access for the first application

Confirm the architecture:

```bash
uname -m
```

The result must be `aarch64`.

The flake uses the user name that is present on this Raspberry Pi: `user`.

## First application

Clone the repository on the Pi and run:

```bash
git clone git@github.com:TudorAndrei/rpi-nix-os-home.git
cd rpi-nix-os-home
scripts/bootstrap-rpi-os.sh
```

The bootstrap script:

1. Installs the required Raspberry Pi OS packages.
2. Sets the host name to `living-room`.
3. Sets the time zone to `Europe/Bucharest`.
4. Enables SSH and installs `keys/rpi.pub` for the current user.
5. Disables the Bluetooth service when it exists.
6. Installs Nix in multi-user mode when Nix is not present.
7. Builds and activates the pinned Home Manager configuration.

Home Manager can print a command named `non-nixos-gpu-setup` during the first activation. Run the exact `sudo /nix/store/.../non-nixos-gpu-setup` command that it prints. This command connects Nix applications to the Raspberry Pi OS graphics libraries. Reboot after this one-time step.

## Apply configuration changes

Run:

```bash
scripts/apply-home.sh
```

The script runs the pinned Home Manager program from this flake. Existing user files receive a dated backup suffix before Home Manager replaces them. The script does not install unmanaged packages.

Validate the complete flake with:

```bash
scripts/check-rpi-os.sh
```

## Plasma Bigscreen automatic login

First, apply Home Manager and confirm that normal Raspberry Pi OS graphics work. Then enable the Bigscreen LightDM session:

```bash
scripts/configure-bigscreen-session.sh
sudo reboot
```

To return to the normal Raspberry Pi OS session:

```bash
scripts/configure-bigscreen-session.sh --disable
sudo reboot
```

The session script changes only these files:

```text
/usr/share/wayland-sessions/plasma-bigscreen-wayland.desktop
/etc/lightdm/lightdm.conf.d/90-living-room-bigscreen.conf
/etc/lightdm/lightdm.conf
```

The script saves the original main LightDM configuration as
`/etc/lightdm/lightdm.conf.living-room-backup`. The `--disable` action restores
that file.

## Update pinned inputs

Update only when you want new package versions:

```bash
scripts/update-inputs.sh
scripts/apply-home.sh
```

Commit `flake.lock` with the configuration. This makes later applications use the same package revisions.

## Repository layout

```text
.
├── flake.nix
├── flake.lock
├── home.nix
├── home
│   ├── bigscreen.nix
│   ├── gaming.nix
│   └── media.nix
├── packages
│   └── plasma-bigscreen.nix
├── keys
│   └── rpi.pub
└── scripts
    ├── bootstrap-rpi-os.sh
    ├── install-nix.sh
    ├── install-system-deps.sh
    ├── apply-home.sh
    ├── check-rpi-os.sh
    ├── configure-bigscreen-session.sh
    └── update-inputs.sh
```

The old NixOS image modules and image-build scripts remain in the repository for reference. The new flake does not import them.

## Important limits

- Stremio and Spotify use Chromium web applications.
- Browser DRM support can limit Spotify playback on ARM64 Linux.
- Moonlight runs without the NixOS-only real-time priority wrapper.
- Home Manager does not change Raspberry Pi firmware or kernel settings.
- Test Bigscreen before you make it the automatic session.

## Primary sources

- [Home Manager standalone flakes](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone)
- [Home Manager GPU support on non-NixOS Linux](https://github.com/nix-community/home-manager/blob/master/docs/manual/usage/gpu-non-nixos.md)
- [Official Nix installer](https://nix.dev/install-nix)
- [Plasma Bigscreen](https://plasma-bigscreen.org/)
- [Moonlight Qt](https://github.com/moonlight-stream/moonlight-qt)

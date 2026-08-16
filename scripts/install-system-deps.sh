#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
public_key="${repo_root}/keys/rpi.pub"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ "$(uname -s)" == "Linux" ]] || fail "this script requires Linux"
[[ "$(uname -m)" == "aarch64" ]] || fail "install 64-bit Raspberry Pi OS first"
[[ "$(id -un)" == "user" ]] || fail "run this script as the user named 'user'"
[[ -f "$public_key" ]] || fail "SSH public key does not exist: $public_key"

sudo apt-get update
sudo apt-get install --yes \
  ca-certificates \
  curl \
  dbus-user-session \
  git \
  libegl1 \
  libgbm1 \
  libgl1 \
  libvulkan1 \
  locales \
  mesa-vulkan-drivers \
  openssh-server \
  pipewire \
  pipewire-pulse \
  pkexec \
  polkitd \
  udisks2 \
  wireplumber \
  xz-utils

sudo hostnamectl set-hostname living-room
sudo timedatectl set-timezone Europe/Bucharest
sudo locale-gen en_US.UTF-8 ro_RO.UTF-8
sudo systemctl enable --now ssh

install -d -m 0700 "${HOME}/.ssh"
touch "${HOME}/.ssh/authorized_keys"
chmod 0600 "${HOME}/.ssh/authorized_keys"

key_text="$(tr -d '\r\n' < "$public_key")"
if ! grep -Fqx -- "$key_text" "${HOME}/.ssh/authorized_keys"; then
  printf '%s\n' "$key_text" >> "${HOME}/.ssh/authorized_keys"
fi

if systemctl list-unit-files bluetooth.service >/dev/null 2>&1; then
  sudo systemctl disable --now bluetooth.service
fi

printf '%s\n' 'Raspberry Pi OS system dependencies are ready.'

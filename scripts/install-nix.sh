#!/usr/bin/env bash

set -Eeuo pipefail

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ "$(uname -s)" == "Linux" ]] || fail "this script requires Linux"
[[ "$(uname -m)" == "aarch64" ]] || fail "install 64-bit Raspberry Pi OS first"
[[ -d /run/systemd/system ]] || fail "the multi-user Nix installer requires systemd"

if command -v nix >/dev/null 2>&1; then
  printf 'Nix is already available: %s\n' "$(nix --version)"
  exit 0
fi

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck source=/dev/null
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if command -v nix >/dev/null 2>&1; then
  printf 'Nix is already installed: %s\n' "$(nix --version)"
  exit 0
fi

sudo apt-get update
sudo apt-get install --yes ca-certificates curl xz-utils

curl --proto '=https' --tlsv1.2 --location https://nixos.org/nix/install \
  | sh -s -- --daemon

printf '%s\n' 'Nix installation finished.'

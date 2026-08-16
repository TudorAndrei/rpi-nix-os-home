#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck source=/dev/null
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

command -v nix >/dev/null 2>&1 || {
  printf '%s\n' 'error: Nix is not available' >&2
  exit 1
}

flake_ref="path:${repo_root}"

nix --extra-experimental-features "nix-command flakes" flake check "$flake_ref"
nix --extra-experimental-features "nix-command flakes" eval \
  --raw \
  "${flake_ref}#homeConfigurations.user.config.home.username"
printf '\nHome Manager flake check passed.\n'

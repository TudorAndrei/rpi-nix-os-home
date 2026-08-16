#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
configuration="user"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck source=/dev/null
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

command -v nix >/dev/null 2>&1 || fail "Nix is not available; run scripts/install-nix.sh first"
[[ "$(uname -m)" == "aarch64" ]] || fail "this configuration requires aarch64-linux"
[[ "$(id -un)" == "$configuration" ]] \
  || fail "this flake is configured for user '$configuration', but the current user is '$(id -un)'"

flake_ref="path:${repo_root}"
home_manager_package="$(
  nix --extra-experimental-features "nix-command flakes" build \
    --no-link \
    --print-out-paths \
    "${flake_ref}#home-manager"
)"

export NIX_CONFIG="${NIX_CONFIG:-}"$'\nexperimental-features = nix-command flakes'
backup_extension="hm-backup-$(date -u +%Y%m%dT%H%M%SZ)"

"${home_manager_package}/bin/home-manager" switch \
  -b "$backup_extension" \
  --flake "${flake_ref}#${configuration}"

printf 'Home Manager configuration applied from %s\n' "$repo_root"

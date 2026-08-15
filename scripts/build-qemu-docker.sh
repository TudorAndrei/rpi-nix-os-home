#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
docker_image="${NIX_DOCKER_IMAGE:-nixos/nix:2.35.1-arm64}"
store_volume="${NIX_DOCKER_VOLUME:-rpi-nix-store}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || fail "docker is not available"
docker info >/dev/null 2>&1 || fail "the Docker engine is not available"
docker volume inspect "$store_volume" >/dev/null 2>&1 || docker volume create "$store_volume" >/dev/null

untracked_files="$(git -C "$repo_root" ls-files --others --exclude-standard -- '*.nix' 'keys/*.pub' 'scripts/*.sh')"
if [[ -n "$untracked_files" ]]; then
  printf 'error: Nix ignores untracked files in a Git flake. Stage or commit these files first:\n%s\n' \
    "$untracked_files" >&2
  exit 1
fi

exec docker run --rm \
  --platform linux/arm64 \
  --volume "${store_volume}:/nix" \
  --volume "${repo_root}:/workspace" \
  --workdir /workspace \
  --env "NIX_CONFIG=experimental-features = nix-command flakes" \
  "$docker_image" \
  /workspace/scripts/build-qemu.sh

#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
docker_image="${NIX_DOCKER_IMAGE:-nixos/nix:2.35.1-arm64}"
store_volume="${NIX_DOCKER_VOLUME:-rpi-nix-store}"
output_format="text"
dry_run=false

usage() {
  cat <<'EOF'
Build the Raspberry Pi SD image through Docker Desktop.

Usage:
  scripts/build-image-docker.sh [options]

Options:
  --output text|json   Select the final output format. Default: text
  --dry-run            Show the Docker command without running it
  -h, --help           Show this help

Environment:
  NIX_DOCKER_IMAGE     Nix ARM64 image. Default: nixos/nix:2.35.1-arm64
  NIX_DOCKER_VOLUME    Persistent Nix store volume. Default: rpi-nix-store
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --output)
      (($# >= 2)) || fail "--output needs text or json"
      output_format="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

case "$output_format" in
  text|json) ;;
  *) fail "--output must be text or json" ;;
esac

docker_command=(
  docker run --rm
  --platform linux/arm64
  --volume "${store_volume}:/nix"
  --volume "${repo_root}:/workspace"
  --workdir /workspace
  --env "NIX_CONFIG=experimental-features = nix-command flakes"
  "$docker_image"
  /workspace/scripts/build-image.sh
  --output-dir /workspace/build
  --output "$output_format"
)

if "$dry_run"; then
  printf 'docker volume create %q\n' "$store_volume"
  printf '%q ' "${docker_command[@]}"
  printf '\n'
  exit 0
fi

command -v docker >/dev/null 2>&1 || fail "docker is not available"

if command -v git >/dev/null 2>&1 && git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  untracked_nix_files="$(git -C "$repo_root" ls-files --others --exclude-standard -- '*.nix' 'keys/*.pub' 'scripts/*.sh')"
  if [[ -n "$untracked_nix_files" ]]; then
    printf 'error: Nix ignores untracked files in a Git flake. Stage or commit these files first:\n%s\n' \
      "$untracked_nix_files" >&2
    exit 1
  fi
fi

docker info >/dev/null 2>&1 || fail "Docker Desktop is not running"
docker volume inspect "$store_volume" >/dev/null 2>&1 || docker volume create "$store_volume" >/dev/null

exec "${docker_command[@]}"

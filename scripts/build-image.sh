#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
output_dir="${repo_root}/build"
output_format="text"
dry_run=false

usage() {
  cat <<'EOF'
Build the Raspberry Pi SD image with Nix.

Usage:
  scripts/build-image.sh [options]

Options:
  --output-dir PATH     Put artifacts in PATH. Default: ./build
  --output text|json   Select the final output format. Default: text
  --dry-run            Show the build commands without running them
  -h, --help           Show this help
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --output-dir)
      (($# >= 2)) || fail "--output-dir needs a path"
      output_dir="$2"
      shift 2
      ;;
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

if "$dry_run"; then
  printf 'cd %q\n' "$repo_root"
  printf 'nix flake lock\n'
  printf 'nix build .#sd-image --print-build-logs --out-link %q\n' "${repo_root}/result"
  printf 'copy image, flake.lock, and SHA256SUMS to %q\n' "$output_dir"
  exit 0
fi

command -v nix >/dev/null 2>&1 || fail "nix is not available"

mkdir -p -- "$output_dir"
output_dir="$(cd -- "$output_dir" && pwd -P)"

cd -- "$repo_root"
nix flake lock
nix build .#sd-image --print-build-logs --out-link "${repo_root}/result"

shopt -s nullglob
images=("${repo_root}"/result/sd-image/*.img.zst)
((${#images[@]} == 1)) || fail "expected one .img.zst file, found ${#images[@]}"

image_name="$(basename -- "${images[0]}")"
image_path="${output_dir}/${image_name}"

cp -L -- "${images[0]}" "$image_path"
cp -- "${repo_root}/flake.lock" "${output_dir}/flake.lock"
(
  cd -- "$output_dir"
  sha256sum -- "$image_name" > SHA256SUMS
)

case "$output_format" in
  text)
    printf 'Image: %s\n' "$image_path"
    printf 'Lock file: %s\n' "${output_dir}/flake.lock"
    printf 'Checksums: %s\n' "${output_dir}/SHA256SUMS"
    ;;
  json)
    printf '{"image":"%s","lock_file":"%s","checksums":"%s"}\n' \
      "$image_path" \
      "${output_dir}/flake.lock" \
      "${output_dir}/SHA256SUMS"
    ;;
esac

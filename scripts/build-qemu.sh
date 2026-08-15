#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
output_dir="${repo_root}/build/qemu"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v nix >/dev/null 2>&1 || fail "nix is not available"

mkdir -p -- "$output_dir"
output_dir="$(cd -- "$output_dir" && pwd -P)"

cd -- "$repo_root"
nix flake lock
nix build .#qemu-bundle --print-build-logs --out-link "${repo_root}/result-qemu"

for artifact_name in Image initrd disk.qcow2 cmdline; do
  source_path="${repo_root}/result-qemu/${artifact_name}"
  destination_path="${output_dir}/${artifact_name}"

  [[ -e "$source_path" ]] || fail "QEMU artifact is missing: $artifact_name"
  if [[ -e "$destination_path" ]]; then
    chmod u+w -- "$destination_path"
  fi
  cp -fL -- "$source_path" "$destination_path"
done

cp -- "${repo_root}/flake.lock" "${output_dir}/flake.lock"
(
  cd -- "$output_dir"
  sha256sum -- Image initrd disk.qcow2 cmdline > SHA256SUMS
)

printf 'QEMU bundle: %s\n' "$output_dir"
printf 'Run it on macOS with: scripts/run-qemu.sh\n'

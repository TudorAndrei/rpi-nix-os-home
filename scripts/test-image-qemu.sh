#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
artifact_dir="${repo_root}/build"
image_path="${1:-}"
qemu_pid=""
mounted_device=""
temp_dir=""

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$qemu_pid" ]] && kill -0 "$qemu_pid" 2>/dev/null; then
    kill "$qemu_pid" 2>/dev/null || true
    wait "$qemu_pid" 2>/dev/null || true
  fi

  if [[ -n "$mounted_device" ]]; then
    hdiutil detach "$mounted_device" >/dev/null 2>&1 || true
  fi

  if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
    rm -rf -- "$temp_dir"
  fi
}

trap cleanup EXIT INT TERM

if [[ -z "$image_path" ]]; then
  [[ -f "${artifact_dir}/SHA256SUMS" ]] \
    || fail "give an image path or build the image first"
  image_name="$(awk 'NF >= 2 { print $2; exit }' "${artifact_dir}/SHA256SUMS")"
  [[ -n "$image_name" ]] || fail "SHA256SUMS does not name an image"
  image_path="${artifact_dir}/${image_name}"
fi

[[ "$(uname -s)" == "Darwin" ]] || fail "this QEMU test currently supports macOS"
[[ -f "$image_path" ]] || fail "image does not exist: $image_path"

for command_name in qemu-system-aarch64 zstd hdiutil dd truncate; do
  command -v "$command_name" >/dev/null 2>&1 || fail "$command_name is required"
done

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/rpi-qemu.XXXXXX")"
available_kib="$(df -k "$temp_dir" | awk 'NR == 2 { print $4 }')"
required_kib=$((16 * 1024 * 1024))
((available_kib >= required_kib)) \
  || fail "QEMU needs at least 16 GiB of free temporary disk space"

raw_image="${temp_dir}/living-room-rpi4.img"
firmware_image="${temp_dir}/firmware.img"
qemu_log="${temp_dir}/qemu.log"

printf 'Decompressing %s\n' "$image_path"
zstd --decompress --force "$image_path" -o "$raw_image"
chmod u+w "$raw_image"

raw_size="$(stat -f '%z' "$raw_image")"
maximum_size=$((16 * 1024 * 1024 * 1024))
((raw_size <= maximum_size)) || fail "the raw image is too large for the 16 GiB QEMU SD card"
truncate -s 16G "$raw_image"

# The repository fixes the firmware partition at 8 MiB with a size of 512 MiB.
dd if="$raw_image" of="$firmware_image" bs=1048576 skip=8 count=512 2>/dev/null

attach_output="$(hdiutil attach -readonly "$firmware_image")"
mounted_device="$(printf '%s\n' "$attach_output" | awk 'NR == 1 { print $1 }')"
firmware_mount="$(printf '%s\n' "$attach_output" | awk -F '\t' 'NF >= 3 { print $NF; exit }')"

[[ -n "$mounted_device" ]] || fail "macOS did not attach the firmware partition"
[[ -d "$firmware_mount" ]] || fail "macOS did not mount the firmware partition"
[[ -f "${firmware_mount}/u-boot.bin" ]] || fail "u-boot.bin is missing"
[[ -f "${firmware_mount}/bcm2711-rpi-4-b.dtb" ]] || fail "the Raspberry Pi 4 device tree is missing"

printf 'Starting the Raspberry Pi 4B QEMU boot test\n'
qemu-system-aarch64 \
  -M raspi4b \
  -kernel "${firmware_mount}/u-boot.bin" \
  -dtb "${firmware_mount}/bcm2711-rpi-4-b.dtb" \
  -drive "file=${raw_image},if=sd,format=raw" \
  -display none \
  -serial stdio \
  -monitor none \
  -no-reboot \
  >"$qemu_log" 2>&1 &
qemu_pid=$!

for ((attempt = 1; attempt <= 90; attempt++)); do
  if grep -Fq 'Starting kernel ...' "$qemu_log"; then
    cat "$qemu_log"
    printf 'QEMU boot test passed: U-Boot loaded the NixOS kernel and initial RAM disk.\n'
    exit 0
  fi

  if ! kill -0 "$qemu_pid" 2>/dev/null; then
    cat "$qemu_log"
    fail "QEMU stopped before the NixOS kernel started"
  fi

  sleep 1
done

cat "$qemu_log"
fail "QEMU did not start the NixOS kernel within 90 seconds"

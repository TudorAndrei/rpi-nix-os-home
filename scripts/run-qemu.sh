#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
bundle_dir="${QEMU_BUNDLE_DIR:-${repo_root}/build/qemu}"
ssh_port="${QEMU_SSH_PORT:-2222}"
headless=false
temporary_dir=""

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$temporary_dir" && -d "$temporary_dir" ]]; then
    rm -rf -- "$temporary_dir"
  fi
}

trap cleanup EXIT INT TERM

while (($# > 0)); do
  case "$1" in
    --headless)
      headless=true
      shift
      ;;
    --ssh-port)
      (($# >= 2)) || fail "--ssh-port needs a port number"
      ssh_port="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Run the living-room NixOS system with QEMU on macOS.

Usage:
  scripts/run-qemu.sh [--headless] [--ssh-port PORT]

The default SSH address is htpc@127.0.0.1 on port 2222.
EOF
      exit 0
      ;;
    *) fail "unknown option: $1" ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || fail "this runner currently supports macOS"
[[ "$ssh_port" =~ ^[0-9]+$ ]] || fail "SSH port must be a number"
((ssh_port >= 1 && ssh_port <= 65535)) || fail "SSH port is outside the valid range"

for command_name in qemu-system-aarch64 qemu-img; do
  command -v "$command_name" >/dev/null 2>&1 || fail "$command_name is required"
done

for artifact_name in Image initrd disk.qcow2 cmdline SHA256SUMS; do
  [[ -f "${bundle_dir}/${artifact_name}" ]] || fail "QEMU artifact is missing: ${bundle_dir}/${artifact_name}"
done

(
  cd -- "$bundle_dir"
  shasum --algorithm 256 --check SHA256SUMS
)

temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/living-room-qemu.XXXXXX")"
overlay_disk="${temporary_dir}/overlay.qcow2"
qemu-img create -q -f qcow2 -F qcow2 -b "${bundle_dir}/disk.qcow2" "$overlay_disk"

qemu_arguments=(
  -name living-room
  -machine virt,accel=hvf
  -cpu host
  -smp 4
  -m 4096
  -kernel "${bundle_dir}/Image"
  -initrd "${bundle_dir}/initrd"
  -append "$(<"${bundle_dir}/cmdline")"
  -drive "if=none,id=root,file=${overlay_disk},format=qcow2"
  -device virtio-blk-pci,drive=root
  -device virtio-gpu-pci
  -device qemu-xhci
  -device usb-kbd
  -device usb-tablet
  -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${ssh_port}-:22"
  -device virtio-net-pci,netdev=net0
  -serial mon:stdio
)

if "$headless"; then
  qemu_arguments+=( -display none )
else
  qemu_arguments+=( -display cocoa )
fi

printf 'SSH: ssh -i ~/.ssh/rpi -p %s htpc@127.0.0.1\n' "$ssh_port"
printf 'Stop QEMU with Control-C.\n'

qemu-system-aarch64 "${qemu_arguments[@]}"

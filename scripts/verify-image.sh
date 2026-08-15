#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
artifact_dir="${1:-${repo_root}/build}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ -d "$artifact_dir" ]] || fail "artifact directory does not exist: $artifact_dir"
[[ -f "${artifact_dir}/SHA256SUMS" ]] || fail "SHA256SUMS is missing from: $artifact_dir"

cd -- "$artifact_dir"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum --check SHA256SUMS
elif command -v shasum >/dev/null 2>&1; then
  shasum --algorithm 256 --check SHA256SUMS
else
  fail "sha256sum or shasum is required"
fi

command -v zstd >/dev/null 2>&1 || fail "zstd is required"
command -v od >/dev/null 2>&1 || fail "od is required"

image_name="$(awk 'NF >= 2 { print $2; exit }' SHA256SUMS)"
[[ -n "$image_name" ]] || fail "SHA256SUMS does not name an image"
[[ -f "$image_name" ]] || fail "image is missing: $image_name"

header_file="$(mktemp "${TMPDIR:-/tmp}/rpi-image-header.XXXXXX")"
trap 'rm -f -- "$header_file"' EXIT

# Nine MiB includes the MBR and the FAT header at the default 8 MiB offset.
# zstd receives SIGPIPE after head has the required prefix. That is expected.
(
  set +o pipefail
  zstd --decompress --stdout -- "$image_name" 2>/dev/null \
    | head -c 9437184 > "$header_file"
)

[[ "$(wc -c < "$header_file" | tr -d '[:space:]')" == "9437184" ]] \
  || fail "could not read the image header"

mbr_signature="$(od -An -tx1 -j 510 -N 2 "$header_file" | tr -d '[:space:]')"
[[ "$mbr_signature" == "55aa" ]] || fail "the MBR signature is not valid"

partition_type="$(od -An -tx1 -j 450 -N 1 "$header_file" | tr -d '[:space:]')"
partition_start="$(od -An -tu4 -j 454 -N 4 "$header_file" | tr -d '[:space:]')"
fat32_offset=$((partition_start * 512 + 82))
fat32_label="$(dd if="$header_file" bs=1 skip="$fat32_offset" count=8 2>/dev/null)"

case "$partition_type" in
  0b|0c) ;;
  *) fail "firmware partition type is 0x${partition_type}, not FAT32" ;;
esac

[[ "$fat32_label" == "FAT32   " ]] \
  || fail "firmware partition is marked as FAT32 in the MBR, but its file system is not FAT32"

printf '%s: boot partition is FAT32 and matches the MBR\n' "$image_name"

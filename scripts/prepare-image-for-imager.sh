#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
artifact_dir="${repo_root}/build"
compressed_image="${1:-}"
output_image="${2:-${artifact_dir}/rpi4-htpc.img}"
temporary_image=""

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$temporary_image" && -f "$temporary_image" ]]; then
    rm -f -- "$temporary_image"
  fi
}

trap cleanup EXIT INT TERM

if [[ -z "$compressed_image" ]]; then
  [[ -f "${artifact_dir}/SHA256SUMS" ]] \
    || fail "give an image path or build the image first"
  image_name="$(awk 'NF >= 2 { print $2; exit }' "${artifact_dir}/SHA256SUMS")"
  [[ -n "$image_name" ]] || fail "SHA256SUMS does not name an image"
  compressed_image="${artifact_dir}/${image_name}"
fi

[[ -f "$compressed_image" ]] || fail "compressed image does not exist: $compressed_image"
[[ "$compressed_image" == *.img.zst ]] || fail "input must be an .img.zst file"
[[ ! -e "$output_image" ]] || fail "output already exists: $output_image"

command -v zstd >/dev/null 2>&1 || fail "zstd is required"
command -v od >/dev/null 2>&1 || fail "od is required"

output_dir="$(dirname -- "$output_image")"
mkdir -p -- "$output_dir"
output_dir="$(cd -- "$output_dir" && pwd -P)"
output_image="${output_dir}/$(basename -- "$output_image")"

available_kib="$(df -k "$output_dir" | awk 'NR == 2 { print $4 }')"
required_kib=$((14 * 1024 * 1024))
((available_kib >= required_kib)) \
  || fail "creating the raw image needs at least 14 GiB of free disk space"

temporary_image="$(mktemp "${output_image}.tmp.XXXXXX")"

printf 'Decompressing %s\n' "$compressed_image"
zstd --decompress --force "$compressed_image" -o "$temporary_image"

mbr_signature="$(od -An -tx1 -j 510 -N 2 "$temporary_image" | tr -d '[:space:]')"
partition_one_type="$(od -An -tx1 -j 450 -N 1 "$temporary_image" | tr -d '[:space:]')"
partition_two_type="$(od -An -tx1 -j 466 -N 1 "$temporary_image" | tr -d '[:space:]')"

[[ "$mbr_signature" == "55aa" ]] || fail "the raw image MBR is not valid"
[[ "$partition_one_type" == "0b" || "$partition_one_type" == "0c" ]] \
  || fail "the raw image firmware partition is not FAT32"
[[ "$partition_two_type" == "83" ]] || fail "the raw image root partition is not Linux"

mv -- "$temporary_image" "$output_image"
temporary_image=""

printf 'Raspberry Pi Imager file: %s\n' "$output_image"
printf 'Select this .img file. Do not select the .img.zst file.\n'

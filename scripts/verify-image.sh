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

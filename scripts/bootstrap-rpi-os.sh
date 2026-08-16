#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

"${script_dir}/install-system-deps.sh"
"${script_dir}/install-nix.sh"

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck source=/dev/null
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

"${script_dir}/apply-home.sh"

#!/usr/bin/env bash

set -Eeuo pipefail

session_name="plasma-bigscreen-wayland"
session_source="${HOME}/.nix-profile/share/wayland-sessions/${session_name}.desktop"
session_target="/usr/share/wayland-sessions/${session_name}.desktop"
lightdm_config="/etc/lightdm/lightdm.conf.d/90-living-room-bigscreen.conf"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

if [[ "${1:-}" == "--disable" ]]; then
  sudo rm -f -- "$lightdm_config" "$session_target"
  printf '%s\n' 'Plasma Bigscreen automatic login is disabled. Reboot to use the Raspberry Pi OS session.'
  exit 0
fi

[[ $# -eq 0 ]] || fail "use no option to enable, or use --disable"
[[ "$(id -un)" == "user" ]] || fail "run this script as the user named 'user'"
[[ -f "$session_source" ]] || fail "apply Home Manager before you configure the Bigscreen session"
systemctl list-unit-files lightdm.service >/dev/null 2>&1 \
  || fail "LightDM is not installed on this Raspberry Pi OS system"

sudo install -D -m 0644 "$session_source" "$session_target"

temporary_config="$(mktemp)"
trap 'rm -f -- "$temporary_config"' EXIT

printf '%s\n' \
  '[Seat:*]' \
  'autologin-user=user' \
  'autologin-user-timeout=0' \
  "autologin-session=${session_name}" \
  "user-session=${session_name}" \
  > "$temporary_config"

sudo install -D -m 0644 "$temporary_config" "$lightdm_config"

printf '%s\n' 'Plasma Bigscreen automatic login is enabled. Reboot to start the session.'

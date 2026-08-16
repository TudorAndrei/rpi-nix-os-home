#!/usr/bin/env bash

set -Eeuo pipefail

session_name="plasma-bigscreen-wayland"
session_source="${HOME}/.nix-profile/share/wayland-sessions/${session_name}.desktop"
session_target="/usr/share/wayland-sessions/${session_name}.desktop"
lightdm_config="/etc/lightdm/lightdm.conf.d/90-living-room-bigscreen.conf"
lightdm_main_config="/etc/lightdm/lightdm.conf"
lightdm_main_backup="/etc/lightdm/lightdm.conf.living-room-backup"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

if [[ "${1:-}" == "--disable" ]]; then
  if sudo test -f "$lightdm_main_backup"; then
    sudo install -m 0644 "$lightdm_main_backup" "$lightdm_main_config"
    sudo rm -f -- "$lightdm_main_backup"
  fi
  sudo rm -f -- "$lightdm_config" "$session_target"
  printf '%s\n' 'Plasma Bigscreen automatic login is disabled. Reboot to use the Raspberry Pi OS session.'
  exit 0
fi

[[ $# -eq 0 ]] || fail "use no option to enable, or use --disable"
[[ "$(id -un)" == "user" ]] || fail "run this script as the user named 'user'"
[[ -f "$session_source" ]] || fail "apply Home Manager before you configure the Bigscreen session"
[[ -f "$lightdm_main_config" ]] || fail "the main LightDM configuration does not exist"
systemctl list-unit-files lightdm.service >/dev/null 2>&1 \
  || fail "LightDM is not installed on this Raspberry Pi OS system"
grep -qE '^autologin-session=' "$lightdm_main_config" \
  || fail "the main LightDM configuration has no autologin-session setting"
grep -qE '^user-session=' "$lightdm_main_config" \
  || fail "the main LightDM configuration has no user-session setting"

sudo install -D -m 0644 "$session_source" "$session_target"

if ! sudo test -e "$lightdm_main_backup"; then
  sudo install -m 0644 "$lightdm_main_config" "$lightdm_main_backup"
fi

sudo sed -i -E \
  -e "s|^autologin-session=.*|autologin-session=${session_name}|" \
  -e "s|^user-session=.*|user-session=${session_name}|" \
  "$lightdm_main_config"

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

effective_config="$(lightdm --show-config 2>&1)"
grep -q "autologin-session=${session_name}" <<< "$effective_config" \
  || fail "LightDM did not accept the Bigscreen autologin session"
grep -q "user-session=${session_name}" <<< "$effective_config" \
  || fail "LightDM did not accept the Bigscreen user session"

printf '%s\n' 'Plasma Bigscreen automatic login is enabled. Reboot to start the session.'

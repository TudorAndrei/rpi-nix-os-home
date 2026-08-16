{ config, lib, pkgs, ... }:

let
  plasmaBigscreenBase =
    pkgs.kdePackages.callPackage ../packages/plasma-bigscreen.nix { };
  plasmaWorkspace = pkgs.kdePackages.plasma-workspace;
  kwin = pkgs.kdePackages.kwin;
  sessionName = "plasma-bigscreen-wayland";

  kwinDrmWrapper = pkgs.writeShellScriptBin "kwin_wayland_wrapper" ''
    export QT_LOGGING_RULES="kwin_core.debug=true;kwin_wayland_drm.debug=true"
    exec ${kwin}/bin/kwin_wayland_wrapper "$@"
  '';

  kwinWaylandProbe = pkgs.writeShellScriptBin "kwin_wayland" ''
    probe_stamp=/tmp/living-room-kwin-gdb-once
    if [[ ! -e "$probe_stamp" ]]; then
      touch "$probe_stamp"
      /usr/bin/gdb \
        --batch \
        --ex "set pagination off" \
        --ex "set debuginfod enabled off" \
        --ex run \
        --ex "thread apply all backtrace" \
        --args ${kwin}/bin/kwin_wayland "$@" \
        >/tmp/living-room-kwin-gdb.log 2>&1
    else
      ${kwin}/bin/kwin_wayland "$@"
    fi
    status=$?
    /usr/bin/logger -t living-room-kwin "kwin_wayland exited with status $status"
    exit "$status"
  '';

  plasmaBigscreen = pkgs.symlinkJoin {
    name = "plasma-bigscreen-home-manager";
    paths = [ plasmaBigscreenBase ];

    postBuild = ''
      for program in plasma-bigscreen-common-env plasma-bigscreen-wayland; do
        rm "$out/bin/$program"
        cp "${plasmaBigscreenBase}/bin/$program" "$out/bin/$program"
        chmod u+w "$out/bin/$program"
      done

      substituteInPlace "$out/bin/plasma-bigscreen-common-env" \
        --replace-fail \
        'QT_QPA_PLATFORM=offscreen plasma-bigscreen-envmanager --apply-settings' \
        "QT_QPA_PLATFORM=offscreen $out/bin/plasma-bigscreen-envmanager --apply-settings"

      substituteInPlace "$out/bin/plasma-bigscreen-wayland" \
        --replace-fail \
        'startplasma-wayland --xwayland' \
        '${plasmaWorkspace}/bin/startplasma-wayland --xwayland'

      substituteInPlace "$out/bin/plasma-bigscreen-wayland" \
        --replace-fail \
        'export EGL_PLATFORM=wayland' \
        'export EGL_PLATFORM=wayland

# Bigscreen sources /etc/profile, which removes the Nix paths on Raspberry Pi
# OS. Restore them before Plasma starts.
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
/usr/bin/systemctl --user import-environment PATH
'

      session="$out/share/wayland-sessions/${sessionName}.desktop"
      rm "$session"
      cp "${plasmaBigscreenBase}/share/wayland-sessions/${sessionName}.desktop" "$session"
      chmod u+w "$session"
      substituteInPlace "$session" \
        --replace-fail \
        '${plasmaBigscreenBase}/bin/plasma-bigscreen-wayland' \
        '${config.home.homeDirectory}/.nix-profile/bin/plasma-bigscreen-wayland'
    '';

    passthru.providedSessions = [ sessionName ];
  };
in
{
  # Raspberry Pi OS starts its user service manager before it loads the Nix
  # session environment. Use Plasma's supported direct start mode instead.
  xdg.configFile."startkderc".text = ''
    [General]
    systemdBoot=false
  '';

  # Plasma imports PATH from the user service manager. Keep the Nix paths in
  # that manager after its environment generators run.
  xdg.configFile."environment.d/10-nix-path.conf".text = ''
    PATH=${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
  '';

  home.packages = with pkgs; [
    plasmaBigscreen
    plasmaWorkspace
    (lib.hiPrio kwinDrmWrapper)
    (lib.hiPrio kwinWaylandProbe)
    kwin
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.konsole
    kdePackages.plasma-nm
    kdePackages.systemsettings
  ];
}

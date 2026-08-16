{ pkgs, ... }:

let
  plasmaBigscreenBase =
    pkgs.kdePackages.callPackage ../packages/plasma-bigscreen.nix { };
  plasmaWorkspace = pkgs.kdePackages.plasma-workspace;
  kwin = pkgs.kdePackages.kwin;
  sessionName = "plasma-bigscreen-wayland";

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
# OS. Plasma reads the same PATH before it starts KWin, so restore and import it.
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user import-environment PATH
fi'

      session="$out/share/wayland-sessions/${sessionName}.desktop"
      rm "$session"
      cp "${plasmaBigscreenBase}/share/wayland-sessions/${sessionName}.desktop" "$session"
      chmod u+w "$session"
      substituteInPlace "$session" \
        --replace-fail \
        '${plasmaBigscreenBase}/bin/plasma-bigscreen-wayland' \
        "$out/bin/plasma-bigscreen-wayland"
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

  home.packages = with pkgs; [
    plasmaBigscreen
    plasmaWorkspace
    kwin
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.konsole
    kdePackages.plasma-nm
    kdePackages.systemsettings
  ];
}

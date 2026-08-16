{ pkgs, ... }:

let
  plasmaBigscreenBase =
    pkgs.kdePackages.callPackage ../packages/plasma-bigscreen.nix { };
  plasmaWorkspace = pkgs.kdePackages.plasma-workspace;
  kwin = pkgs.kdePackages.kwin;
  sessionName = "plasma-bigscreen-wayland";

  plasmaUserUnits = pkgs.buildEnv {
    name = "plasma-bigscreen-user-units";
    paths = [
      plasmaWorkspace
      kwin
    ];
    pathsToLink = [ "/share/systemd/user" ];
    ignoreCollisions = true;
  };

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
  # The Raspberry Pi OS user manager starts before the Nix session changes
  # XDG_DATA_DIRS. Put the Plasma units in its standard user unit directory.
  xdg.configFile."systemd/user" = {
    source = "${plasmaUserUnits}/share/systemd/user";
    recursive = true;
  };

  home.packages = with pkgs; [
    plasmaBigscreen
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.konsole
    kdePackages.plasma-nm
    kdePackages.systemsettings
  ];
}

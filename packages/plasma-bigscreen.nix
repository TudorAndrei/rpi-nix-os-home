{
  lib,
  mkKdeDerivation,
  fetchFromGitLab,
  pkg-config,
  kdeconnect-kde,
  kdeclarative,
  kscreen,
  libcec,
  milou,
  plasma-nano,
  plasma-nm,
  plasma-workspace,
  plasma-wayland-protocols,
  qcoro,
  qtmultimedia,
  qtwayland,
  qtwebengine,
  sdl3,
  wayland,
}:

mkKdeDerivation {
  pname = "plasma-bigscreen";
  version = "unstable-2026-05-11";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "plasma";
    repo = "plasma-bigscreen";
    rev = "5602f65bcac23fc8f8a8a3f69c130da4fd00df19";
    hash = "sha256-APdiGFNLLvDk4+5igVgw/GDJnrPIkq3gmGBSvs7v/8U=";
  };

  extraNativeBuildInputs = [ pkg-config ];

  extraBuildInputs = [
    kdeconnect-kde
    kdeclarative
    kscreen
    libcec
    milou
    plasma-nano
    plasma-nm
    plasma-wayland-protocols
    qcoro
    qtmultimedia
    qtwayland
    qtwebengine
    sdl3
    wayland
  ];

  dontQmlLint = true;

  extraCmakeFlags = [ "-DQT_FIND_PRIVATE_MODULES=1" ];

  postPatch = ''
    # Qt 6.11 no longer exposes the QML registration functions through
    # transitive includes.
    substituteInPlace kcms/display/displaysettings.cpp \
      --replace-fail '#include "displaysettings.h"' \
      $'#include "displaysettings.h"\n#include <QtQml/qqml.h>'

    substituteInPlace kcms/webapps/webappskcm.cpp \
      --replace-fail '#include "webappskcm.h"' \
      $'#include "webappskcm.h"\n#include <QtQml/qqml.h>'

    substituteInPlace kcms/bluetooth/bluetooth.cpp \
      --replace-fail '#include "bluetooth.h"' \
      $'#include "bluetooth.h"\n#include <QtQml/qqml.h>'

    substituteInPlace bin/plasma-bigscreen-wayland.in \
      --replace-fail @KDE_INSTALL_FULL_LIBEXECDIR@ "${plasma-workspace}/libexec"

    substituteInPlace bin/plasma-bigscreen-wayland.desktop.cmake \
      --replace-fail @CMAKE_INSTALL_FULL_LIBEXECDIR@ "${plasma-workspace}/libexec"

    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(PROJECT_VERSION "6.5.80")' \
      'set(PROJECT_VERSION "${plasma-workspace.version}")'
  '';

  passthru.providedSessions = [ "plasma-bigscreen-wayland" ];

  meta.platforms = lib.platforms.linux;
}

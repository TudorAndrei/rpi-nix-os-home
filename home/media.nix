{ pkgs, ... }:

let
  chromium = pkgs.chromium;
in
{
  home.packages = with pkgs; [
    chromium
    kodi
    libva-utils
    mpv
    vlc
  ];

  xdg.desktopEntries = {
    spotify-web = {
      name = "Spotify";
      genericName = "Music player";
      comment = "Open Spotify Web";
      icon = "audio-headphones";
      exec = "${chromium}/bin/chromium --app=https://open.spotify.com/ --start-maximized --no-first-run";
      categories = [
        "Audio"
        "AudioVideo"
      ];
      terminal = false;
    };

    stremio-web = {
      name = "Stremio";
      genericName = "Streaming media";
      comment = "Open Stremio Web";
      icon = "video-display";
      exec = "${chromium}/bin/chromium --app=https://web.stremio.com/ --start-maximized --no-first-run";
      categories = [
        "AudioVideo"
        "Video"
      ];
      terminal = false;
    };
  };
}

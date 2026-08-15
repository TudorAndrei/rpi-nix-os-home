{ pkgs, ... }:

let
  chromium = pkgs.chromium;

  stremioWeb = pkgs.makeDesktopItem {
    name = "stremio-web";
    desktopName = "Stremio";
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

  spotifyWeb = pkgs.makeDesktopItem {
    name = "spotify-web";
    desktopName = "Spotify";
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
in
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true;
  };

  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    chromium
    kodi
    libva-utils
    mpv
    spotifyWeb
    stremioWeb
    vlc
  ];
}

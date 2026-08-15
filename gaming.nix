{ pkgs, ... }:

{
  programs.moonlight-qt = {
    enable = true;
    capSysNice = true;
    # Moonlight 6.1.0 uses an API that FFmpeg 9 removed.
    package = pkgs.moonlight-qt.override { ffmpeg = pkgs.ffmpeg_8; };
  };

  environment.systemPackages = with pkgs; [
    evtest
  ];
}

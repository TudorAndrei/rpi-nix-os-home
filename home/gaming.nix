{ pkgs, ... }:

let
  moonlight = pkgs.moonlight-qt.override { ffmpeg = pkgs.ffmpeg_8; };
in
{
  home.packages = [
    moonlight
    pkgs.evtest
  ];
}

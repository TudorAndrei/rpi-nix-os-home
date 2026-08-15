{ pkgs, ... }:

{
  programs.moonlight-qt = {
    enable = true;
    capSysNice = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        ControllerMode = "dual";
        Experimental = true;
        FastConnectable = true;
      };

      # These intervals reduce lost input from Xbox Series BLE controllers.
      LE = {
        MinConnectionInterval = 7;
        MaxConnectionInterval = 9;
        ConnectionLatency = 0;
      };
    };
  };

  hardware.xpadneo.enable = true;

  environment.systemPackages = with pkgs; [
    bluez
    evtest
  ];
}

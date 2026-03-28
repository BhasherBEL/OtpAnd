{ ... }:
{
  android = {
    enable = true;
    flutter.enable = true;
    buildTools.version = [ "35.0.0" ];
    platforms.version = [
      "33"
      "34"
      "35"
      "36"
    ];
  };
}

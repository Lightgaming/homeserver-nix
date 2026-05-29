{ ... }:
{
  services.syncthing = {
    enable = true;
    user = "hardclip";
    dataDir = "/home/hardclip/syncthing"; # Where your synced files live
    configDir = "/home/hardclip/.config/syncthing"; # Where settings live
    guiAddress = "127.0.0.1:8384";
    settings.gui = {
      insecureSkipHostcheck = true;
    };
  };
}
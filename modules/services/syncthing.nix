{ ... }:
{
  services.syncthing = {
    enable = true;
    user = "hardclip";
    dataDir = "/home/hardclip/syncthing"; # Where your synced files live
    configDir = "/home/hardclip/.config/syncthing"; # Where settings live
  };
}
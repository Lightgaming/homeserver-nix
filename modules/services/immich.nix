{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
  };

  users.users.immich.extraGroups = [ "video" "render" ];

  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = false;
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };
}
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
    # null exposes all devices to the Immich service.
    accelerationDevices = [ "/dev/dri/renderD128" ];
    # Immich sets up its own Postgres and Redis automatically in NixOS
  };
}
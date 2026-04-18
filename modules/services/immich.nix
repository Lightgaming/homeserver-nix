{ config, pkgs, ... }:

{
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = false;
    # Immich sets up its own Postgres and Redis automatically in NixOS
  };
}
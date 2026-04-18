{ config, pkgs, ... }:

{
  services.immich = {
    enable = true;
    port = 2283;
    host = "127.0.0.1";
    openFirewall = false;
    # Immich sets up its own Postgres and Redis automatically in NixOS
  };
}
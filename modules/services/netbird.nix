{ config, pkgs, ... }:

{
  # Enable the Netbird client daemon
  services.netbird.enable = true;

  # Add the CLI to system packages
  environment.systemPackages = [ pkgs.netbird ];
}
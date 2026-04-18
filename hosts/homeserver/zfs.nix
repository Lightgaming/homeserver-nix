{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = pkgs.lib.mkForce false;

  networking.hostId = "81872454";
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partlabel";

  swapDevices = pkgs.lib.mkForce [ {
    device = "/dev/disk/by-partuuid/d4988e4b-8db3-4b93-9e08-7fe04995dbc0";
    randomEncryption.enable = true;
  } ];
}

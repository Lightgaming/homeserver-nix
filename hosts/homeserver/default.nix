{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    
    ../../modules/core/ssh.nix
    ../../modules/core/security.nix
    ../../modules/core/acme.nix

    ../../modules/services/proxy.nix
    ../../modules/services/netbird.nix
    ../../modules/services/adguard.nix
    ../../modules/services/immich.nix
    ../../modules/services/vaultwarden.nix
    ../../modules/services/matrix.nix
  ];

  # --- Bootloader Configuration ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = lib.mkForce false;

  # --- ZFS Configuration ---
  # ZFS requires a hostId to track pool imports
  networking.hostId = "81872454";
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partlabel";

  # CRITICAL for unstable + ZFS: Ensure the kernel version is compatible with ZFS
  # boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # --- Swap & Encryption ---
  swapDevices = lib.mkForce [ {
    device = "/dev/disk/by-partuuid/d4988e4b-8db3-4b93-9e08-7fe04995dbc0";
    randomEncryption.enable = true;
  } ];

  # --- System Networking & Core ---
  networking.hostName = "homeserver";
  networking.networkmanager.enable = true;

  # Required by AdGuard Home to prevent port 53 conflicts
  services.resolved.settings = {
    Resolve = {
      DNSStubListener = "no";
    };
  };

  # --- User Configuration ---
  users.users.hardclip = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3... your-public-key-here" # REPLACE THIS
    ];
  };

  system.stateVersion = "24.05";
}
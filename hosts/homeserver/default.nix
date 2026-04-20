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
    ../../modules/services/matrix-admin.nix
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

  # VScode Server
  services.vscode-server.enable = true;

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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHK1vPSECfZl2tViKtMAh1FF9qWo6cHFxniNWZfo7FNA flotz@saint"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHnyd8p+T+OiC4Hj+1pCJFqfO3KkgMVxBHPwF9dP++v saint@DESKTOP-U5QUN5R"
    ];
  };

  programs.git.enable = true;

  system.stateVersion = "24.05";
}

{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 4;
    bantime = "12h";
    ignoreIP = [ "127.0.0.0/8" "100.100.124.164/10" "192.168.0.10" ]; 
    jails = {
      sshd.settings = {
        enabled = true;
        mode = "aggressive";
        findtime = 600;
      };
    };
  };

  networking.firewall = {
    enable = true;
    # Keep only explicitly required internet-facing ports.
    allowedTCPPorts = [ 22 53 80 443 ];
    allowedUDPPorts = [ 53 3478 ];
    trustedInterfaces = [ "wt0" ];
  };

  # Automatic system upgrades
  system.autoUpgrade = {
    enable = true;
    # Pull directly from your GitHub flake so config + packages update unattended.
    flake = "github:Lightgaming/homeserver-nix#homeserver";
    flags = [
      "--refresh"
      "-L" 
    ];
    dates = "daily";
    randomizedDelaySec = "45min";
    operation = "switch";
  };

  # Keep the store healthy on long-running hosts.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
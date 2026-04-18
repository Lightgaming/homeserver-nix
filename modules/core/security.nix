{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    ignoreIP = [ "127.0.0.0/8" "100.64.0.0/10" ]; 
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 53 80 443 8080 ];
    allowedUDPPorts = [ 53 3478 ];
    trustedInterfaces = [ "wt0" ];
  };

  # Automatic system upgrades
  system.autoUpgrade = {
    enable = true;
    # Tell Nix to look for updates in your local flake directory
    flake = "/home/hardclip/flake"; 
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" 
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
}
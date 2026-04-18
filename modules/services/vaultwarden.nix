{ config, pkgs, ... }:

{
  services.vaultwarden = {
    enable = true;
    # Backup setup is highly recommended for vaultwarden
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "https://vault.lotz.zip"; # Change to HTTPS if you configure certs
      SIGNUPS_ALLOWED = false; # Turn true temporarily to create your admin account
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
    };
  };
}
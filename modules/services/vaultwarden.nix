{ config, pkgs, ... }:

{
  services.vaultwarden = {
    enable = true;
    # Backup setup is highly recommended for vaultwarden
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "https://vault.lotz.zip"; # Change to HTTPS if you configure certs
      SIGNUPS_ALLOWED = false; # Enable temporarily only when intentionally onboarding users
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
    };
  };
}
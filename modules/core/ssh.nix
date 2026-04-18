{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      # Harden SSH: Disable root login and require SSH keys (no passwords)
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };
}

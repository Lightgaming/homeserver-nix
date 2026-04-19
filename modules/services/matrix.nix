{ config, pkgs, ... }:

{
  services.matrix-synapse = {
    enable = true;
    # Keep instance secrets out of the Nix store and git history.
    extraConfigFiles = [ "/var/lib/secrets/matrix-synapse-secrets.yaml" ];
    settings = {
      server_name = "lotz.zip"; 
      public_baseurl = "https://matrix.lotz.zip";
      enable_registration = true;
      # Required by newer Synapse when open registrations are enabled.
      # Disable both options again after creating your initial admin account.
      enable_registration_without_verification = true;

      listeners = [{
        port = 8008;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [{
          names = [ "client" "federation" ];
          compress = false;
        }];
      }];
    };
  };
}
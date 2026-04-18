{ config, pkgs, ... }:

{
  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = "lotz.zip"; 
      public_baseurl = "https://matrix.lotz.zip";
      enable_registration = false;
      
      # Generates required keys automatically on first run
      macaroon_secret_key = "CHANGE_ME_IN_PRODUCTION"; 
      registration_shared_secret = "CHANGE_ME_IN_PRODUCTION";

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
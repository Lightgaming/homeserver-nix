{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts = {
      "vault.lotz.zip" = {
        useACMEHost = "lotz.zip";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:8222";
      };
      
      "immich.lotz.zip" = {
        useACMEHost = "lotz.zip";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:2283";
        locations."/".extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          client_max_body_size 50000M;
          proxy_read_timeout 600s;
        '';
      };

      "matrix.lotz.zip" = {
        useACMEHost = "lotz.zip";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:8008";
        locations."/_matrix".proxyPass = "http://127.0.0.1:8008";
        locations."/_synapse/client".proxyPass = "http://127.0.0.1:8008";
      };

      "chat.lotz.zip" = {
        useACMEHost = "lotz.zip";
        forceSSL = true;
        # We configure Element by overriding the static package here
        root = pkgs.element-web.override {
          conf = {
            default_server_config = {
              "m.homeserver" = {
                base_url = "https://matrix.lotz.zip";
                server_name = "lotz.zip";
              };
            };
            disable_custom_urls = true;
            disable_guests = true;
          };
        };
      };

      "dns.lotz.zip" = {
        useACMEHost = "lotz.zip";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:3000";
      };
    };
  };
}
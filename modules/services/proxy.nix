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

      "netbird.lotz.zip" = {
        useACMEHost = "lotz.zip";
        forceSSL = true;
        enableHSTS = false;
        http2 = true;
        extraConfig = ''
          # Required for long-lived gRPC/WebSocket connections.
          client_header_timeout 1d;
          client_body_timeout 1d;

          # Clear previously cached HSTS policy for this host.
          add_header Strict-Transport-Security "max-age=0" always;

          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Scheme $scheme;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header X-Forwarded-Host $host;
          grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

          location ~ ^/(relay|ws-proxy/) {
            proxy_pass http://127.0.0.1:8081;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 1d;
          }

          location ~ ^/(signalexchange\.SignalExchange|management\.ManagementService|management\.ProxyService)/ {
            grpc_pass grpc://127.0.0.1:8081;
            grpc_read_timeout 1d;
            grpc_send_timeout 1d;
            grpc_socket_keepalive on;
          }

          location ~ ^/(api|oauth2)/ {
            proxy_pass http://127.0.0.1:8081;
            proxy_set_header Host $host;
          }

          location / {
            proxy_pass http://127.0.0.1:8080;
          }
        '';
      };
    };
  };
}
{ config, pkgs, ... }:

{
  # Keep the NetBird CLI available for joining/testing clients.
  environment.systemPackages = [ pkgs.netbird ];

  # Run NetBird client daemon on the host as part of declarative config.
  services.netbird.enable = true;

  # Avoid state-dir collision with the self-hosted server data in /var/lib/netbird.
  systemd.services.netbird.environment = {
    NB_STATE_DIR = "/var/lib/netbird-client";
  };

  # Keep NetBird server config (including auth/encryption keys) out of git and the Nix store.
  environment.etc."netbird/config.yaml" = {
    source = "/var/lib/secrets/netbird/config.yaml";
    mode = "0400";
  };

  # Run NetBird as a declarative NixOS-managed container service.
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  systemd.tmpfiles.rules = [
    "d /var/lib/netbird 0750 root root -"
    "d /var/lib/netbird/config 0750 root root -"
    "d /var/lib/netbird/dashboard 0750 root root -"
    "d /var/lib/netbird-client 0750 root root -"
  ];

  # Declarative auto-connect for the homeserver peer.
  # Put the setup key in /var/lib/secrets/netbird-setup-key (content: key only).
  systemd.services.netbird-up = {
    description = "Bring up NetBird peer from declarative config";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "netbird.service" ];
    wants = [ "network-online.target" "netbird.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      LoadCredential = [ "setupkey:/var/lib/secrets/netbird-setup-key" ];
      ExecStart = pkgs.writeShellScript "netbird-up" ''
        set -eu

        key_file="/run/credentials/netbird-up.service/setupkey"
        if [ ! -s "$key_file" ]; then
          echo "netbird setup key missing: $key_file" >&2
          exit 1
        fi

        exec ${pkgs.netbird}/bin/netbird up \
          --management-url https://netbird.lotz.zip \
          --setup-key "$(cat "$key_file")" \
          --hostname homeserver
      '';
      ExecStop = "${pkgs.netbird}/bin/netbird down";
    };
  };

  virtualisation.oci-containers.containers = {
    netbird-server = {
      image = "netbirdio/netbird-server:latest";
      ports = [
        "127.0.0.1:8081:80/tcp"
        "3478:3478/udp"
      ];
      volumes = [
        "/var/lib/netbird:/var/lib/netbird"
        "/etc/netbird/config.yaml:/etc/netbird/config.yaml:ro"
      ];
      cmd = [ "--config" "/etc/netbird/config.yaml" ];
    };

    netbird-dashboard = {
      image = "netbirdio/dashboard:latest";
      ports = [ "127.0.0.1:8080:80/tcp" ];
      volumes = [
        # Optional dashboard overrides (env/js). Keep directory for future use.
        "/var/lib/netbird/dashboard:/app/data"
      ];
      environment = {
        NETBIRD_MGMT_API_ENDPOINT = "https://netbird.lotz.zip";
        NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://netbird.lotz.zip";
        AUTH_AUDIENCE = "netbird-dashboard";
        AUTH_CLIENT_ID = "netbird-dashboard";
        AUTH_CLIENT_SECRET = "";
        AUTH_AUTHORITY = "https://netbird.lotz.zip/oauth2";
        USE_AUTH0 = "false";
        AUTH_SUPPORTED_SCOPES = "openid profile email groups";
        AUTH_REDIRECT_URI = "/nb-auth";
        AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
      };
    };
  };
}
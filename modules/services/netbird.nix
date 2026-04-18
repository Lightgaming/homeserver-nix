{ config, pkgs, ... }:

{
  # Keep the NetBird CLI available for joining/testing clients.
  environment.systemPackages = [ pkgs.netbird ];

  # Run NetBird as a declarative NixOS-managed container service.
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  systemd.tmpfiles.rules = [
    "d /var/lib/netbird 0750 root root -"
    "d /var/lib/netbird/config 0750 root root -"
    "d /var/lib/netbird/dashboard 0750 root root -"
  ];

  virtualisation.oci-containers.containers = {
    netbird-server = {
      image = "netbirdio/netbird-server:latest";
      ports = [
        "127.0.0.1:8081:80/tcp"
        "3478:3478/udp"
      ];
      volumes = [
        "/var/lib/netbird:/var/lib/netbird"
        # Create this file from the NetBird quickstart template:
        # /var/lib/netbird/config/config.yaml
        "/var/lib/netbird/config/config.yaml:/etc/netbird/config.yaml:ro"
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
      };
    };
  };
}
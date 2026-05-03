{ config, pkgs, ... }:

{
  # Synapse Admin dashboard (web UI) exposed via nginx only.
  virtualisation.oci-containers.containers = {
    synapse-admin = {
      image = "awesometechnologies/synapse-admin:latest";
      ports = [ "127.0.0.1:8082:80/tcp" ];
      environment = {
        REACT_APP_SERVER = "https://matrix.lotz.zip";
      };
    };
  };
}

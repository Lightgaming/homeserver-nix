{ config, ... }:

let
  timezone = if config.time.timeZone != null then config.time.timeZone else "UTC";
  minecraftRoot = "/data/minecraft";
  craftyRoot = "${minecraftRoot}/crafty";
in
{
  # Crafty is a full Minecraft panel and can create/start/stop servers directly.
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  systemd.tmpfiles.rules = [
    "d ${minecraftRoot} 0775 hardclip hardclip -"
    "d ${craftyRoot} 0775 hardclip hardclip -"
    "d ${craftyRoot}/backups 0775 hardclip hardclip -"
    "d ${craftyRoot}/logs 0775 hardclip hardclip -"
    "d ${craftyRoot}/servers 0775 hardclip hardclip -"
    "d ${craftyRoot}/config 0775 hardclip hardclip -"
    "d ${craftyRoot}/import 0775 hardclip hardclip -"
  ];

  # Crafty allocates server ports from this range by default.
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 25500;
      to = 25600;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 25500;
      to = 25600;
    }
  ];
  networking.firewall.allowedUDPPorts = [ 19132 ];

  virtualisation.oci-containers.containers.minecraft-dashboard = {
    image = "registry.gitlab.com/crafty-controller/crafty-4:latest";
    ports = [
      "127.0.0.1:8443:8443/tcp"
      "8123:8123/tcp"
      "19132:19132/udp"
      "25500-25600:25500-25600/tcp"
      "25500-25600:25500-25600/udp"
    ];
    volumes = [
      "${craftyRoot}/backups:/crafty/backups"
      "${craftyRoot}/logs:/crafty/logs"
      "${craftyRoot}/servers:/crafty/servers"
      "${craftyRoot}/config:/crafty/app/config"
      "${craftyRoot}/import:/crafty/import"
    ];
    environment = {
      TZ = timezone;
    };
  };
}
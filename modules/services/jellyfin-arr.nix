{ config, ... }:

let
  mediaRoot = "/data";
  configRoot = "${mediaRoot}/config";
  timezone = if config.time.timeZone != null then config.time.timeZone else "UTC";

  lsioEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = timezone;
    UMASK = "002";
  };
in
{
  # Keep everything declarative and managed by NixOS.
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Keep download + media paths on the same filesystem so hardlinks work.
  systemd.tmpfiles.rules = [
    "d ${mediaRoot} 0775 hardclip hardclip -"
    "d ${mediaRoot}/config 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/jellyfin 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/jellyfin/cache 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/jellyseerr 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/qbittorrent 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/prowlarr 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/radarr 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/sonarr 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/lidarr 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/readarr 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/bazarr 0775 hardclip hardclip -"
    "d ${mediaRoot}/config/flaresolverr 0775 hardclip hardclip -"

    "d ${mediaRoot}/torrents 0775 hardclip hardclip -"
    "d ${mediaRoot}/torrents/incomplete 0775 hardclip hardclip -"
    "d ${mediaRoot}/torrents/complete 0775 hardclip hardclip -"
    "d ${mediaRoot}/torrents/complete/movies 0775 hardclip hardclip -"
    "d ${mediaRoot}/torrents/complete/tv 0775 hardclip hardclip -"
    "d ${mediaRoot}/torrents/complete/music 0775 hardclip hardclip -"
    "d ${mediaRoot}/torrents/complete/books 0775 hardclip hardclip -"

    "d ${mediaRoot}/media 0775 hardclip hardclip -"
    "d ${mediaRoot}/media/movies 0775 hardclip hardclip -"
    "d ${mediaRoot}/media/tv 0775 hardclip hardclip -"
    "d ${mediaRoot}/media/music 0775 hardclip hardclip -"
    "d ${mediaRoot}/media/books 0775 hardclip hardclip -"
  ];

  # qBittorrent peer traffic.
  networking.firewall.allowedTCPPorts = [ 6881 ];
  networking.firewall.allowedUDPPorts = [ 6881 ];

  virtualisation.oci-containers.containers = {
    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      environment = lsioEnv // {
        WEBUI_PORT = "8080";
      };
      volumes = [
        "${configRoot}/qbittorrent:/config"
        "${mediaRoot}/torrents:/data/torrents"
      ];
      extraOptions = [ "--network=host" ];
    };

    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      environment = lsioEnv;
      volumes = [ "${configRoot}/prowlarr:/config" ];
      extraOptions = [ "--network=host" ];
    };

    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      environment = {
        LOG_LEVEL = "info";
        TZ = timezone;
      };
      volumes = [ "${configRoot}/flaresolverr:/config" ];
      extraOptions = [ "--network=host" ];
    };

    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      environment = lsioEnv;
      volumes = [
        "${configRoot}/radarr:/config"
        "${mediaRoot}:/data"
      ];
      extraOptions = [ "--network=host" ];
    };

    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      environment = lsioEnv;
      volumes = [
        "${configRoot}/sonarr:/config"
        "${mediaRoot}:/data"
      ];
      extraOptions = [ "--network=host" ];
    };

    lidarr = {
      image = "lscr.io/linuxserver/lidarr:latest";
      environment = lsioEnv;
      volumes = [
        "${configRoot}/lidarr:/config"
        "${mediaRoot}:/data"
      ];
      extraOptions = [ "--network=host" ];
    };

    readarr = {
      image = "lscr.io/linuxserver/readarr:develop";
      environment = lsioEnv;
      volumes = [
        "${configRoot}/readarr:/config"
        "${mediaRoot}:/data"
      ];
      extraOptions = [ "--network=host" ];
    };

    bazarr = {
      image = "lscr.io/linuxserver/bazarr:latest";
      environment = lsioEnv;
      volumes = [
        "${configRoot}/bazarr:/config"
        "${mediaRoot}/media:/data/media"
      ];
      extraOptions = [ "--network=host" ];
    };

    jellyfin = {
      image = "jellyfin/jellyfin:latest";
      environment = {
        TZ = timezone;
      };
      volumes = [
        "${configRoot}/jellyfin:/config"
        "${configRoot}/jellyfin/cache:/cache"
        "${mediaRoot}/media:/media"
      ];
      extraOptions = [ "--network=host" ];
    };

    jellyseerr = {
      image = "fallenbagel/jellyseerr:latest";
      environment = {
        TZ = timezone;
      };
      volumes = [ "${configRoot}/jellyseerr:/app/config" ];
      extraOptions = [ "--network=host" ];
    };
  };

  services.nginx.virtualHosts = {
    "jellyfin.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
      };
    };

    "requests.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:5055";
        proxyWebsockets = true;
      };
    };

    "prowlarr.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:9696";
    };

    "radarr.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:7878";
    };

    "sonarr.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8989";
    };

    "lidarr.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8686";
    };

    "readarr.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8787";
    };

    "bazarr.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:6767";
    };

    "qbittorrent.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };
  };
}

{ config, pkgs, ... }:

let
  mediaRoot = "/data";
  configRoot = "${mediaRoot}/config";
  timezone = if config.time.timeZone != null then config.time.timeZone else "UTC";
  qbitWebUiUser = "admin";
  qbitWebUiPassword = "MediaStack123!";

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

  # Keep qB paths/categories/auth stable so ARR can import consistently.
  systemd.services.qbittorrent-bootstrap = {
    description = "Bootstrap qBittorrent settings";
    wantedBy = [ "multi-user.target" ];
    before = [ "docker-qbittorrent.service" ];
    script = ''
      set -eu

      qbit_dir="${configRoot}/qbittorrent/qBittorrent"
      qbit_conf="$qbit_dir/qBittorrent.conf"

      mkdir -p "$qbit_dir"

      if [ ! -f "$qbit_conf" ]; then
        cat > "$qbit_conf" <<'EOF'
[AutoRun]
enabled=false
program=

[Preferences]
WebUI\Address=*
WebUI\Port=18080
WebUI\ServerDomains=*
EOF
      fi

      set_kv() {
        key="$1"
        value="$2"
        if grep -q "^$key=" "$qbit_conf"; then
          sed -i "s|^$key=.*|$key=$value|" "$qbit_conf"
        else
          printf '%s=%s\n' "$key" "$value" >> "$qbit_conf"
        fi
      }

      set_kv 'Session\DefaultSavePath' '/data/torrents/complete/'
      set_kv 'Session\TempPath' '/data/torrents/incomplete/'
      set_kv 'Downloads\SavePath' '/data/torrents/complete/'
      set_kv 'Downloads\TempPath' '/data/torrents/incomplete/'
      set_kv 'Downloads\TempPathEnabled' 'true'
      set_kv 'WebUI\Address' '*'
      set_kv 'WebUI\Port' '18080'
      set_kv 'WebUI\ServerDomains' '*'
      set_kv 'WebUI\AuthSubnetWhitelist' '127.0.0.1/32'
      set_kv 'WebUI\AuthSubnetWhitelistEnabled' 'true'

      # Let WEBUI_PASSWORD env var take over auth; remove stale config entries.
      sed -i '/^WebUI\\Username=/d' "$qbit_conf"
      sed -i '/^WebUI\\Password=/d' "$qbit_conf"
      sed -i '/^WebUI\\Password_PBKDF2=/d' "$qbit_conf"

      cat > "$qbit_dir/categories.json" <<'EOF'
{
  "movies": { "savePath": "/data/torrents/complete/movies" },
  "tv": { "savePath": "/data/torrents/complete/tv" },
  "music": { "savePath": "/data/torrents/complete/music" }
}
EOF
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  systemd.services.docker-qbittorrent = {
    requires = [ "qbittorrent-bootstrap.service" ];
    after = [ "qbittorrent-bootstrap.service" ];
  };

  # Wire services together after they are up so downloads/imports work immediately.
  systemd.services.arr-bootstrap = {
    description = "Bootstrap ARR download clients and Prowlarr apps";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "docker-qbittorrent.service"
      "docker-radarr.service"
      "docker-sonarr.service"
      "docker-prowlarr.service"
    ];
    after = [
      "docker-qbittorrent.service"
      "docker-radarr.service"
      "docker-sonarr.service"
      "docker-prowlarr.service"
    ];
    path = with pkgs; [
      coreutils
      curl
      gnugrep
      gnused
    ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -eu

      wait_http() {
        url="$1"
        tries=0
        until curl -fsS "$url" >/dev/null 2>&1; do
          tries=$((tries + 1))
          if [ "$tries" -ge 90 ]; then
            echo "Timed out waiting for $url" >&2
            return 1
          fi
          sleep 2
        done
      }

      api_key() {
        sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' "$1" | head -n1
      }

      wait_http "http://127.0.0.1:7878/ping"
      wait_http "http://127.0.0.1:8989/ping"
      wait_http "http://127.0.0.1:9696/ping"
      wait_http "http://127.0.0.1:18080/"

      qb_cookie="$(mktemp)"
      trap 'rm -f "$qb_cookie" /tmp/radarr-qb.json /tmp/sonarr-qb.json /tmp/prowlarr-radarr.json /tmp/prowlarr-sonarr.json' EXIT

      qb_http="$(curl -sS -c "$qb_cookie" -w '%{http_code}' -o /dev/null --data 'username=${qbitWebUiUser}&password=${qbitWebUiPassword}' http://127.0.0.1:18080/api/v2/auth/login)"
      if [ "$qb_http" != "200" ] && [ "$qb_http" != "204" ]; then
        echo "qBittorrent login failed in arr-bootstrap (HTTP $qb_http)" >&2
        exit 1
      fi

      for pair in "movies:/data/torrents/complete/movies" "tv:/data/torrents/complete/tv" "music:/data/torrents/complete/music"; do
        category="$(echo "$pair" | cut -d: -f1)"
        save_path="$(echo "$pair" | cut -d: -f2-)"
        curl -fsS -b "$qb_cookie" --data-urlencode "category=$category" --data-urlencode "savePath=$save_path" http://127.0.0.1:18080/api/v2/torrents/createCategory >/dev/null || true
      done

      radarr_key="$(api_key ${configRoot}/radarr/config.xml)"
      sonarr_key="$(api_key ${configRoot}/sonarr/config.xml)"
      prowlarr_key="$(api_key ${configRoot}/prowlarr/config.xml)"

      if ! curl -fsS -H "X-Api-Key: $radarr_key" http://127.0.0.1:7878/api/v3/downloadclient | grep -q '"implementation":"QBittorrent"'; then
        cat > /tmp/radarr-qb.json <<EOF
{
  "enable": true,
  "priority": 1,
  "removeCompletedDownloads": true,
  "removeFailedDownloads": true,
  "name": "qBittorrent",
  "implementation": "QBittorrent",
  "configContract": "QBittorrentSettings",
  "fields": [
    { "name": "host", "value": "127.0.0.1" },
    { "name": "port", "value": 18080 },
    { "name": "useSsl", "value": false },
    { "name": "urlBase", "value": "" },
    { "name": "username", "value": "${qbitWebUiUser}" },
    { "name": "password", "value": "${qbitWebUiPassword}" },
    { "name": "movieCategory", "value": "movies" },
    { "name": "movieImportedCategory", "value": "movies-imported" }
  ]
}
EOF
        curl -fsS -X POST -H "X-Api-Key: $radarr_key" -H "Content-Type: application/json" --data @/tmp/radarr-qb.json http://127.0.0.1:7878/api/v3/downloadclient >/dev/null
      fi

      if ! curl -fsS -H "X-Api-Key: $sonarr_key" http://127.0.0.1:8989/api/v3/downloadclient | grep -q '"implementation":"QBittorrent"'; then
        cat > /tmp/sonarr-qb.json <<EOF
{
  "enable": true,
  "priority": 1,
  "removeCompletedDownloads": true,
  "removeFailedDownloads": true,
  "name": "qBittorrent",
  "implementation": "QBittorrent",
  "configContract": "QBittorrentSettings",
  "fields": [
    { "name": "host", "value": "127.0.0.1" },
    { "name": "port", "value": 18080 },
    { "name": "useSsl", "value": false },
    { "name": "urlBase", "value": "" },
    { "name": "username", "value": "${qbitWebUiUser}" },
    { "name": "password", "value": "${qbitWebUiPassword}" },
    { "name": "tvCategory", "value": "tv" },
    { "name": "tvImportedCategory", "value": "tv-imported" }
  ]
}
EOF
        curl -fsS -X POST -H "X-Api-Key: $sonarr_key" -H "Content-Type: application/json" --data @/tmp/sonarr-qb.json http://127.0.0.1:8989/api/v3/downloadclient >/dev/null
      fi

      if ! curl -fsS -H "X-Api-Key: $prowlarr_key" http://127.0.0.1:9696/api/v1/applications | grep -q '"implementation":"Radarr"'; then
        cat > /tmp/prowlarr-radarr.json <<EOF
{
  "name": "Radarr",
  "syncLevel": "fullSync",
  "enable": true,
  "implementation": "Radarr",
  "configContract": "RadarrSettings",
  "tags": [],
  "fields": [
    { "name": "prowlarrUrl", "value": "http://127.0.0.1:9696" },
    { "name": "baseUrl", "value": "http://127.0.0.1:7878" },
    { "name": "apiKey", "value": "$radarr_key" }
  ]
}
EOF
        curl -fsS -X POST -H "X-Api-Key: $prowlarr_key" -H "Content-Type: application/json" --data @/tmp/prowlarr-radarr.json http://127.0.0.1:9696/api/v1/applications >/dev/null
      fi

      if ! curl -fsS -H "X-Api-Key: $prowlarr_key" http://127.0.0.1:9696/api/v1/applications | grep -q '"implementation":"Sonarr"'; then
        cat > /tmp/prowlarr-sonarr.json <<EOF
{
  "name": "Sonarr",
  "syncLevel": "fullSync",
  "enable": true,
  "implementation": "Sonarr",
  "configContract": "SonarrSettings",
  "tags": [],
  "fields": [
    { "name": "prowlarrUrl", "value": "http://127.0.0.1:9696" },
    { "name": "baseUrl", "value": "http://127.0.0.1:8989" },
    { "name": "apiKey", "value": "$sonarr_key" }
  ]
}
EOF
        curl -fsS -X POST -H "X-Api-Key: $prowlarr_key" -H "Content-Type: application/json" --data @/tmp/prowlarr-sonarr.json http://127.0.0.1:9696/api/v1/applications >/dev/null
      fi
    '';
  };

  virtualisation.oci-containers.containers = {
    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      environment = lsioEnv // {
        WEBUI_PORT = "18080";
        WEBUI_PASSWORD = "${qbitWebUiPassword}";
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

    "bazarr.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:6767";
    };

    "qbittorrent.lotz.zip" = {
      useACMEHost = "lotz.zip";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:18080";
        proxyWebsockets = true;
      };
    };
  };
}

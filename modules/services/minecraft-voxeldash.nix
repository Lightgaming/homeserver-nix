{ config, pkgs, ... }:

let
  timezone = if config.time.timeZone != null then config.time.timeZone else "UTC";
  minecraftData = "/data/minecraft";
in
{
  # Keep the Minecraft + VoxelDash stack declarative under NixOS.
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  systemd.tmpfiles.rules = [
    "d ${minecraftData} 0775 hardclip hardclip -"
    "d ${minecraftData}/plugins 0775 hardclip hardclip -"
  ];

  # Java Edition default server port.
  networking.firewall.allowedTCPPorts = [ 25565 ];

  # Install the latest VoxelDash plugin from GitHub releases before Minecraft starts.
  systemd.services.voxeldash-plugin = {
    description = "Download latest VoxelDash plugin";
    before = [ "docker-minecraft.service" ];
    path = with pkgs; [
      coreutils
      curl
      gnugrep
    ];
    script = ''
      set -eu

      plugin_dir="${minecraftData}/plugins"
      plugin_path="$plugin_dir/VoxelDash.jar"

      mkdir -p "$plugin_dir"

      release_url="$(curl -fsSL https://api.github.com/repos/gnmyt/VoxelDash/releases/latest | grep -oE 'https://[^\"]+\.jar' | head -n1 || true)"
      if [ -z "$release_url" ]; then
        echo "Could not resolve latest VoxelDash release jar URL" >&2
        exit 1
      fi

      tmp_jar="$(mktemp /tmp/voxeldash.XXXXXX.jar)"
      trap 'rm -f "$tmp_jar"' EXIT

      curl -fsSL "$release_url" -o "$tmp_jar"
      install -m 0644 "$tmp_jar" "$plugin_path"
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  virtualisation.oci-containers.containers.minecraft = {
    image = "itzg/minecraft-server:java21";
    ports = [
      "25565:25565/tcp"
      "127.0.0.1:7867:7867/tcp"
    ];
    volumes = [
      "${minecraftData}:/data"
    ];
    environment = {
      EULA = "TRUE";
      TYPE = "PAPER";
      VERSION = "LATEST";
      TZ = timezone;
      MEMORY = "6G";
    };
  };

  systemd.services.docker-minecraft = {
    requires = [ "voxeldash-plugin.service" ];
    after = [ "voxeldash-plugin.service" ];
  };
}
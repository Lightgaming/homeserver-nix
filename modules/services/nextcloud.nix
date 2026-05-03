{ ... }: 
{
  virtualisation.oci-containers.containers.nextcloud = {
    image = "nextcloud:33-apache";
    ports = [ "127.0.0.1:8999:80/tcp" ];
    volumes = [
      "/var/lib/nextcloud/html:/var/www/html"
    ];
    environment = {
      NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud.lotz.zip";
      TRUSTED_PROXIES = "127.0.0.1 100.64.0.0/10";
      OVERWRITEHOST = "nextcloud.lotz.zip";
      OVERWRITEPROTOCOL = "https";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nextcloud 0750 root root -"
    "d /var/lib/nextcloud/html 0750 root root -"
  ];
}
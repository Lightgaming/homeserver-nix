{ ... }: 
{
  services.nextcloud = {
    enable = true;
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    config.dbtype = "sqlite";
    hostName = "nextcloud.lotz.zip";
    https = true;
  };
}
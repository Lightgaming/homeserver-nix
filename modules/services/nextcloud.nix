{ ... }: 
{
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.lotz.zip";
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    config.dbtype = "sqlite";
  };
}
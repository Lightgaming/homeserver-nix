{ pkgs, ... }: 
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    config.dbtype = "sqlite";
    hostName = "nextcloud.lotz.zip";
  };
}
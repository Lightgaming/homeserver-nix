{ pkgs, ... }: 
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    nginx.enable = true;
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    config.dbtype = "sqlite";
    hostName = "nextcloud.lotz.zip";
    https = true;
    settings = {
      overwritehost = "nextcloud.lotz.zip";
      overwriteprotocol = "https";
      trusted_proxies = [ "127.0.0.1" "::1" "100.64.0.0/10" ];
    };
  };

  # Reuse wildcard cert managed in modules/core/acme.nix.
  services.nginx.virtualHosts."nextcloud.lotz.zip".useACMEHost = "lotz.zip";
}
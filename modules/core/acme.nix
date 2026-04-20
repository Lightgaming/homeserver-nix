{ config, pkgs, ... }:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = "florian@lotz.zip";

    certs."lotz.zip" = {
      domain = "*.lotz.zip";
      extraDomainNames = [ "lotz.zip" ];
      dnsProvider = "cloudflare";
      # The credentials file must contain: CF_DNS_API_TOKEN=your_token_here
      environmentFile = "/var/lib/secrets/cloudflare-api-token";
      
      # Allow Nginx to read the certificates
      group = config.services.nginx.group;
      
      # Reload Nginx when the certificate renews
      reloadServices = [ "nginx.service" ];
    };
  };
}
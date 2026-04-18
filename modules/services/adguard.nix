{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;
    port = 3000;
    openFirewall = false; # Handled by our central security module
    settings = {
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        bootstrap_dns = [ "9.9.9.9" "1.1.1.1" ];
        upstream_dns = [ "https://dns10.quad9.net/dns-query" ];
      };
    };
  };
}
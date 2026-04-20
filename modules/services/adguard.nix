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
      filtering = {
        protection_enables = true;
        filtering_enables = true;
        parental_enabled = true;
      };
      filters = map(url: { enabled = true; url = url; }) [
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"  # The Big List of Hacked Malware Web Sites
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"  # malicious url blocklist
      ];
    };
  };
}
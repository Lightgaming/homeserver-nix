{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;
    port = 3000;
    openFirewall = false;
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
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"  # AdGuard Base Filter
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt" # AdGuard DNS Popup Hosts Filter
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_49.txt" # HaGeZi's Ultimate Blocklist
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_69.txt" # ShadowWhisperer Tracking List
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_46.txt" # HaGeZi's Anti-Privacy Blocklist
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_67.txt" # HaGeZi's Apple Tracker Blocklist
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_61.txt" # HaGeZi's Samsung Tracker Blocklist
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_63.txt" # HaGeZi's Windows/Office Tracker Blocklist
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt" # Phishing URL Blocklist (PhishTank and OpenPhish)
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt" # Dandelion Sprout's Anti-Malware List
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_71.txt" # HaGeZi's DNS Rebind Protection
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt"  # NoCoin Filter List
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_42.txt" # ShadowWhisperer's Malware List
        "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt" # uBlock₀ filters – Badware risks
      ];
    };
  };
}
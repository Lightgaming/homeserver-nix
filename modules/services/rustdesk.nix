{ ... }:

{
  services.nginx.virtualHosts."rustdesk.lotz.zip" = {
    useACMEHost = "lotz.zip";
    forceSSL = true;
    locations."/" = {
      # RustDesk web portal running on the Windows machine.
      proxyPass = "http://192.168.0.10:21114";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}

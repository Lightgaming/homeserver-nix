{ pkgs, ...}:
{
  services.github-runners.ravr-deploy = {
    enable = true;
    url = "https://github.com/Lightgaming/ravr";
    tokenFile = "/run/secrets/github-runner-token";
    user = "hardclip";
    extraPackages = [ pkgs.git pkgs.openssh pkgs.docker-client pkgs.docker-compose ];
  };
}
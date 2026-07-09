{ config, pkgs, lib, ... }:

{
  services.atticd = {
    enable = true;

    # --- Secrets ---
    # Generate the environment file on the server:
    #   openssl genrsa -traditional 4096 | base64 -w0
    # Then create /var/lib/secrets/atticd-env with:
    #   ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="<output-from-above>"
    environmentFile = "/var/lib/secrets/atticd-env";

    settings = {
      # Listen on localhost only — nginx handles TLS termination
      listen = "127.0.0.1:8090";

      # The canonical API endpoint for this server (used in token generation etc.)
      api-endpoint = "https://cache.lotz.zip/";

      # JWT config (required — empty object means use defaults with RS256 from env)
      jwt = { };

      # --- Chunking Configuration ---
      # Warning: Changing these after initial setup reduces deduplication
      # until new data is uploaded with the new cutpoints.
      chunking = {
        # Minimum NAR size to trigger chunking (0 = disabled, 1 = all)
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024;           # 16 KiB
        avg-size = 64 * 1024;           # 64 KiB
        max-size = 256 * 1024;          # 256 KiB
      };

      # --- Compression ---
      compression = {
        type = "zstd";
      };

      # --- Garbage Collection ---
      garbage-collection = {
        interval = "12 hours";
      };
    };
  };

  # Allow attic through the firewall (nginx proxies from outside)
  # networking.firewall.allowedTCPPorts = [ 8090 ]; # not needed — localhost only

  # --- Nix Configuration: Use this cache as a substituter ---
  # After creating your first cache via `atticd-atticadm make-token` and
  # `attic cache create <name>`, uncomment and fill in the public key:
  #
  # nix.settings = {
  #   substituters = [ "https://cache.lotz.zip/<cache-name>" ];
  #   trusted-public-keys = [ "<cache-name>:<public-key>" ];
  # };
  #
  # You can find the public key with: attic cache info <cache-name>
}

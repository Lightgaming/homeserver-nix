# Attic Nix Binary Cache

Self-hosted Nix binary cache at `cache.lotz.zip`.

## Architecture

```
Client (laptop/desktop)          Server (homeserver)
  │                                │
  │  attic push / nix copy         │
  │──────────────────────────────▶ │  nginx :443 (TLS)
  │                                │    └─ atticd :8090 (localhost)
  │  attic login (JWT auth)        │         ├─ SQLite: /var/lib/atticd/server.db
  │  nix substituter (basic auth)  │         └─ Storage: /var/lib/atticd/storage
  │                                │
```

- **Auth**: JWT tokens for API, basic auth (netrc) for Nix substituter
- **Server**: `atticd` runs as a systemd service, localhost-only, behind nginx+TLS
- **Storage**: Local filesystem with ZSTD compression and chunk-based deduplication

---

## Server Setup

Already configured via NixOS module (`modules/services/attic.nix`).

### Generating the JWT secret

Run once on the server:

```bash
openssl genrsa -traditional 4096 | base64 -w0
```

Create the secrets file:

```bash
sudo mkdir -p /var/lib/secrets
echo 'ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="<output-from-above>"' | \
  sudo tee /var/lib/secrets/atticd-env > /dev/null
sudo chmod 600 /var/lib/secrets/atticd-env
```

Rebuild and switch:

```bash
sudo nixos-rebuild switch --flake ~/flake#homeserver
```

### Management commands

```bash
# Check service status
systemctl status atticd

# View logs
journalctl -u atticd -f

# Restart after config/secret changes
sudo systemctl restart atticd
```

---

## Client Setup

### Install the attic CLI

On any NixOS or nix-darwin machine:

```bash
# One-time use:
nix shell nixpkgs#attic-client -c attic <command>

# Or add to system packages
environment.systemPackages = [ pkgs.attic-client ];
```

### Generate a token (on the server)

```bash
sudo atticd-atticadm make-token --sub "hardclip" --validity "1y" \
  --push "*" --pull "*" --create-cache "*"
```

This outputs a JWT (starts with `eyJ...`). Copy it to the client machine.

### Log in on the client

```bash
attic login homeserver https://cache.lotz.zip/ <JWT>
```

This stores credentials in `~/.config/attic/config.toml`.

### Verify connection

```bash
attic server info homeserver
```

---

## Cache Management

### Create a cache

```bash
attic cache create my-cache
```

### List caches

```bash
attic cache list
```

### Show cache info (includes public key)

```bash
attic cache info my-cache
```

Output includes:

```
             Public: true
         Public Key: my-cache:<base64-key>
Binary Cache Endpoint: https://cache.lotz.zip/my-cache
         API Endpoint: https://cache.lotz.zip/
```

### Configure retention (optional)

```bash
# Auto-delete paths older than 30 days
attic cache configure my-cache --retention-period 30d

# Reset to server default (no GC)
attic cache configure my-cache --reset-retention-period
```

### Delete a cache

```bash
attic cache destroy my-cache
```

---

## Pushing & Pulling

### Push store paths from a flake

```bash
# From any flake project:
nix flake archive --json | jq -r '.path' | xargs nix copy --to "https://cache.lotz.zip/my-cache"

# Or with attic (recommended):
attic push my-cache
```

### Configure Nix to use the cache

On the **client machine** (automatically, via `attic use`):

```bash
attic use my-cache
# This updates ~/.config/nix/nix.conf and ~/.netrc
```

On the **server** (declaratively, in `modules/services/attic.nix`):

```nix
nix.settings = {
  substituters = [ "https://cache.lotz.zip/my-cache" ];
  trusted-public-keys = [ "my-cache:<public-key>" ];
};
```

### Pull from the cache

Nix will automatically use the cache as a substituter after `attic use` or declarative configuration. No manual pull needed.

---

## Token Reference

| Flag | Description | Example |
|---|---|---|
| `--sub` | Subject (username) | `"hardclip"` |
| `--validity` | Token lifetime | `"1y"`, `"90d"`, `"1h"` |
| `--push` | Push permission (glob) | `"*"`, `"my-cache"` |
| `--pull` | Pull permission (glob) | `"*"`, `"my-cache"` |
| `--create-cache` | Create cache permission (glob) | `"*"`, `"my-*"` |

### Token examples

```bash
# Full admin
sudo atticd-atticadm make-token --sub "hardclip" --validity "1y" \
  --push "*" --pull "*" --create-cache "*"

# Read-only CI token
sudo atticd-atticadm make-token --sub "github-runner" --validity "90d" \
  --pull "ci-*"

# Single cache push/pull
sudo atticd-atticadm make-token --sub "dev" --validity "1y" \
  --push "my-cache" --pull "my-cache"
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Unauthorized` | Token expired or wrong secret. Regenerate token and `attic login` again. |
| `Connection refused` | Check `systemctl status atticd` and `systemctl status nginx`. |
| `Could not resolve host` | DNS issue on the client. Verify `cache.lotz.zip` resolves. |
| Token not working after restart | The env file changed. Regenerate the token — JWTs are tied to the signing key. |

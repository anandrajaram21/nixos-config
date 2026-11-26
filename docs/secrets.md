# Secrets

[← README](../README.md)

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and
committed in `secrets/`. `.sops.yaml` lists who can decrypt them:

- `altf4`: a personal age key at
  `~/Library/Application Support/sops/age/keys.txt` on each Mac. It's used to
  edit secrets, and Macs also decrypt with it. Keep a backup of it.
- One key per NixOS host (e.g. `saturn`), derived from its SSH host key and
  used at boot and on rebuild to decrypt into `/run/secrets/`.

Secrets are split by who needs them:

| File | Recipients | Holds |
|---|---|---|
| `secrets/common.yaml` | `altf4` and every NixOS host | Secrets every host uses |
| `secrets/<host>.yaml` | `altf4` and that host | Secrets only that host uses |

`modules/system/shared.nix` declares the common secrets. A host-only secret
goes in `hosts/<host>/default.nix` with `sopsFile = ../../secrets/<host>.yaml;`.

| Secret | File | Used for |
|---|---|---|
| `github_ssh_key` | `common.yaml` | GitHub SSH auth and commit signing for altf4 |
| `cloudflare_api_token` | `saturn.yaml` | Caddy's DNS challenge for `*.home.anandrajaram.dev` |

```bash
# Edit secrets (on a Mac; modules/home/mac-user.nix installs sops and age)
sops secrets/common.yaml

# After adding a host or key to .sops.yaml, re-encrypt for the new recipients
sops updatekeys secrets/common.yaml
```

To add a NixOS host, get its age key from its SSH host key with
`nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub`, add it
under `keys`, add it to the `common.yaml` rule, add a `<host>.yaml` rule, and
run `sops updatekeys secrets/common.yaml`. After a reinstall, a host gets a new
host key, so update its entry the same way before rebuilding.

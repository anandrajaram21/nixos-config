<img src="assets/icon.svg" width="64" height="64" alt="">

# nixos-config

Declarative configuration for my machines, built with
[flakes](https://nixos.wiki/wiki/Flakes),
[Home Manager](https://github.com/nix-community/home-manager),
[nix-darwin](https://github.com/nix-darwin/nix-darwin),
[disko](https://github.com/nix-community/disko) and
[sops-nix](https://github.com/Mic92/sops-nix).

| Host | Kind | Platform | Guide |
|---|---|---|---|
| `mercury` | Apple Silicon MacBook | macOS with nix-darwin, `aarch64-darwin` | [docs/mercury.md](docs/mercury.md) |
| `saturn` | Headless home server (i7-8750H, GTX 1060) | NixOS, `x86_64-linux` | [docs/saturn.md](docs/saturn.md) |

## What's in it

- **Shell and dev tools, on every host:** fish with starship, zoxide, direnv
  and eza; neovim; git and gh with SSH commit signing; Node (fnm), Python (uv),
  Bun, pnpm, PHP; Claude Code, OpenCode, Grok Build, Antigravity CLI and
  T3 Code with their settings.
- **mercury:** macOS defaults (Dock, trackpad, keyboard, menu bar), wallpaper,
  and every GUI app (Ghostty, 1Password, Raycast, OrbStack, VS Code, Obsidian,
  Slack, Spotify, Zoom, …) from nixpkgs, Homebrew casks or the App Store.
- **saturn:** headless NixOS with SSH, Tailscale and the NVIDIA driver, a T3
  Code server, and a media stack: Jellyfin, Sonarr, Radarr, Lidarr, Prowlarr,
  Bazarr, Seerr, qBittorrent, slskd and Soularr, each at
  `https://<name>.home.anandrajaram.dev` over Tailscale through Caddy.
  Monitoring: Homepage as the start page, Beszel for CPU, memory, disk,
  network and GPU history, and Scrutiny for disk health. AI hub: CLIProxyAPI
  for pooling OAuth CLI subscriptions behind one API endpoint.
- **Secrets:** encrypted with sops in `secrets/`, decrypted at activation.

## Ideology

- **Lego bricks.** Every file in `modules/` is one self-contained feature: an
  app, a service, a driver, a shell setup. Bricks never import each other.
  A host is just a list of the bricks it wants, so adding a machine means
  picking rows from the catalog, not untangling shared files.
- **Explicit over magic.** Every import is a literal path you can grep. No
  directory loaders, no `allowUnfree = true` (unfree packages are allowed by
  name, in the brick that needs them).
- **Apps are pairs.** `modules/system/apps/<app>.nix` installs an app;
  `modules/home/apps/<app>.nix` configures it, if it has config. One can
  change without touching the other.
- **Bricks stay generic.** A brick sets up the basics so it works on any
  host. Machine specifics (hardware, mounts, bus IDs, the domain) live in
  `hosts/<name>/default.nix`. Server services only install, run and route;
  their settings are made once in each app's web UI.
- **Declarative where it pays off.** Dotfiles, macOS preferences and app
  settings I care about are pinned and reapplied on every switch. Sign-ins,
  permissions and per-app UI setup that Nix can't do well are written down
  in `docs/` instead.
- **nixpkgs first.** Homebrew and the App Store only fill gaps nixpkgs can't
  cover on macOS.
- **Nothing secret in the store.** Secrets live encrypted in the repo and are
  referenced by path, never written into Nix files.
- **Rolling, but pinned.** Inputs track `nixos-unstable`; `flake.lock` pins
  them, and they're only bumped on purpose.

## Layout

```
.
├── flake.nix                          # inputs, mkNixos/mkDarwin (embedded Home Manager), hosts, checks, formatter
├── flake.lock                         # pinned input revisions
├── justfile                           # check / eval-all / build / switch / fmt / update recipes
├── .sops.yaml                         # which age keys can decrypt secrets/
├── secrets/
│   ├── common.yaml                    # sops-encrypted secrets for every host
│   └── saturn.yaml                    # saturn only: Cloudflare token, CLIProxyAPI management key
├── modules/                           # database of bricks; bricks never import each other
│   ├── system/
│   │   ├── shared.nix                 # every host (required): unfree list, sops, nix, timezone, fish
│   │   ├── fonts.nix                  # every host: GeistMono Nerd Font
│   │   ├── nixos-base.nix             # every NixOS host: boot, nix gc, user, tailscale, base packages
│   │   ├── server.nix                 # headless servers: OpenSSH
│   │   ├── nvidia.nix                 # NVIDIA driver + PRIME offload; defaults suit Turing and newer
│   │   ├── darwin-base.nix            # every Mac: primary user, nix gc, sops key, Homebrew
│   │   ├── mac-defaults.nix           # every Mac: Dock, trackpad, keyboard, menu bar, lock
│   │   ├── services/                  # NixOS: one brick per server service, each served as <name>.home.<domain>
│   │   │   ├── caddy.nix              # HTTPS reverse proxy, Tailscale only; defines homeProxy.{domain,routes}
│   │   │   ├── media.nix              # `media` group and media.dataDir (/data); the host mounts it
│   │   │   ├── jellyfin.nix           # media server
│   │   │   └── qbittorrent.nix, prowlarr.nix, flaresolverr.nix, sonarr.nix, radarr.nix,
│   │   │       lidarr.nix, bazarr.nix, seerr.nix, slskd.nix, soularr.nix   # download and request stack
│   │   │   └── beszel.nix, beszel-agent.nix, scrutiny.nix, homepage.nix   # monitoring and start page
│   │   │   └── cliproxyapi.nix        # OpenAI/Claude/Gemini/Codex/Grok API proxy for OAuth subscriptions
│   │   └── apps/                      # one brick per app; each installs it (nixpkgs, cask or App Store)
│   │       ├── t3code-cask.nix        # Mac: T3 Code app (official cask, updates itself)
│   │       ├── t3code-server.nix      # headless NixOS: T3 Code server `t3` as a boot service (official prebuilt release)
│   │       ├── t3code-appimage.nix    # NixOS desktop (venus): T3 Code app (official AppImage)
│   │       ├── grok-build.nix         # every host: Grok Build CLI (`grok`)
│   │       ├── antigravity-cli.nix    # every host: Antigravity CLI (`agy`)
│   │       ├── obsidian.nix, slack.nix, spotify.nix, zoom.nix   # cross-OS, used on the Mac
│   │       └── 1password.nix, betterdisplay.nix, cmux.nix, ghostty.nix, grok-bot.nix,
│   │           helium-browser.nix, hex.nix, local.nix, orbstack.nix, raycast.nix,
│   │           tablepro.nix, tailscale-app.nix, velja.nix, vorssaint.nix,
│   │           vscode.nix                                           # Mac-only
│   └── home/
│       ├── shell.nix                  # every host: fish, starship, zoxide, direnv, eza, nvim
│       ├── git.nix                    # every host: git, gh, SSH signing, GitHub SSH key
│       ├── dev.nix                    # every host: CLI tools, Node (fnm), Python (uv), Bun, PHP
│       ├── claude-code.nix            # every host: Claude Code and its settings.json
│       ├── opencode.nix               # every host: OpenCode and its settings
│       ├── mac-user.nix               # Mac: PATHs, sops/age, ~/Life folders
│       ├── mac-wallpaper.nix          # Mac: desktop wallpaper (assets/wallpapers)
│       └── apps/                      # app config only; the app comes from system/apps/<same name>*.nix
│           ├── t3code.nix             # every host: T3 Code settings
│           ├── ghostty.nix            # every host: Ghostty config
│           ├── grok-build.nix         # every host: Grok Build config (CLIProxyAPI routing)
│           ├── 1password.nix          # Mac: SSH through the 1Password agent
│           ├── orbstack.nix           # Mac: OrbStack shell init and SSH config
│           ├── cmux.nix               # Mac: cmux config
│           ├── hex.nix                # Mac: Hex settings
│           └── vorssaint.nix          # Mac: Vorssaint settings
├── hosts/
│   ├── mercury/default.nix            # imports + hostname, stateVersions
│   └── saturn/
│       ├── default.nix                # imports + GTX 1060 overrides, data disk mounts, secrets, stateVersions
│       ├── hardware-configuration.nix # generated with --no-filesystems
│       └── disko.nix                  # SSD partition layout (also generates fileSystems)
├── docs/                              # how-tos: setup, everyday use, troubleshooting
│   ├── mercury.md                     # Mac: fresh setup, manual steps, app settings, permissions
│   ├── saturn.md                      # server: hardware, services, storage, install, known issues
│   ├── saturn-media-setup.md          # one-time web UI setup for saturn's media stack
│   ├── saturn-monitoring.md           # Homepage, Beszel and Scrutiny: what each shows, first-run setup
│   ├── secrets.md                     # sops: keys, files, editing
│   └── adding-a-host.md               # new machine checklist
├── scripts/mac-setup.sh               # fresh-Mac bootstrap: Homebrew, Nix, age key, first switch
├── scripts/sync-settings.py           # `just sync`: copy apps' UI settings back into modules/home/apps
├── assets/                            # icon.svg, wallpapers/
└── AGENTS.md                          # rules, brick catalog and checklists for AI agents (CLAUDE.md links here)
```

Each host's `default.nix` is its explicit list of system bricks (`imports`)
and Home Manager bricks (`home-manager.users.altf4.imports`), plus anything
specific to that machine.

| Input | Tracks | Why |
|---|---|---|
| `nixpkgs` | `nixos-unstable` | Packages and NixOS modules (rolling) |
| `home-manager` | `master` | User-level config; follows our `nixpkgs` |
| `disko` | `master` | Declarative partitioning; follows our `nixpkgs` |
| `sops-nix` | `master` | Encrypted secrets; follows our `nixpkgs` |
| `nix-darwin` | `master` | macOS system config; follows our `nixpkgs` |

## Docs

| Guide | Covers |
|---|---|
| [docs/mercury.md](docs/mercury.md) | Fresh Mac setup and manual steps, everyday use, syncing app settings, where apps get installed from, privacy permissions after updates |
| [docs/saturn.md](docs/saturn.md) | Hardware, everyday use and rollbacks, services and HTTPS, the data disk, fresh install, NVIDIA, known issues |
| [docs/saturn-media-setup.md](docs/saturn-media-setup.md) | One-time web UI setup for every media app, in order |
| [docs/saturn-monitoring.md](docs/saturn-monitoring.md) | Homepage, Beszel and Scrutiny: what each shows, first-run setup |
| [docs/secrets.md](docs/secrets.md) | sops keys and files, editing secrets, adding a host's key |
| [docs/adding-a-host.md](docs/adding-a-host.md) | Bringing a new machine into the flake |
| [AGENTS.md](AGENTS.md) | Rules, brick catalog and checklists for AI coding agents |

```bash
just switch-mercury   # or just switch-saturn, on that machine
just check            # every host still evaluates
```

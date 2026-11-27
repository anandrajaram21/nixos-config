# AGENTS.md

Guidance for AI coding agents working in this repo (`CLAUDE.md` is a symlink
to this file). `README.md` says what the config has and why it's built this
way; `docs/` holds every how-to (setup, everyday use, troubleshooting);
this file holds the rules, the brick catalog and the checklists for agents.

## Machines

| Host | Hardware | Stack | Status |
|---|---|---|---|
| `mercury` | Apple Silicon MacBook (`aarch64-darwin`) | nix-darwin + Homebrew + Home Manager | live |
| `saturn` | Headless home server, i7-8750H + GTX 1060 Mobile (`x86_64-linux`) | NixOS + disko + Home Manager | live |
| `venus` | Gaming laptop, RTX 4060, full desktop | NixOS + Home Manager | planned, not created |

Inputs track `nixos-unstable`; `flake.lock` pins them. Don't update inputs
unless a build is broken.

## Architecture

```
flake.nix                 mkNixos / mkDarwin: inputs' modules + embedded Home Manager + ./hosts/<name>
hosts/<name>/default.nix  the host's shopping list of modules + hardware and host-only overrides
modules/system/*.nix      system bricks (NixOS / nix-darwin)
modules/system/apps/*.nix one brick per app: installs it (nixpkgs, Homebrew cask, App Store)
modules/system/services/*.nix one brick per server service (NixOS), served via Caddy
modules/home/*.nix        Home Manager bricks for user altf4
modules/home/apps/*.nix   app config only, paired by name with system/apps/<app>.nix
```

Rules:

- **Module database.** Each file in `modules/` is a standalone brick.
  Modules never import other modules; only `hosts/<name>/default.nix`
  imports modules, and it lists every one explicitly.
- **Apps are pairs.** `modules/system/apps/<app>.nix` installs one app
  (and allows it if unfree); `modules/home/apps/<app>.nix`, only when the app
  has config, configures it and never installs it. A host imports both.
- **Services register their own route.** `services/caddy.nix` defines
  `homeProxy.domain` (set by the host) and `homeProxy.routes`; each service
  brick sets `homeProxy.routes.<name> = <port>;` and becomes
  `https://<name>.<domain>` on Tailscale. Media services use
  `config.media.dataDir` and group `media` from `services/media.nix`, and
  set `RequiresMountsFor` on it. Bricks only install, run and route a
  service; app settings are made in its web UI (`docs/saturn-media-setup.md`),
  so a brick works on any host.
- **No auto-import magic.** No `builtins.readDir`, `listFilesRecursive` or
  directory loaders. Every import is a literal, greppable path.
- **System vs. home split.** `modules/system/` holds NixOS/nix-darwin
  options; `modules/home/` holds Home Manager options. A host imports home
  bricks under `home-manager.users.altf4.imports`. Home Manager is embedded
  (`useGlobalPkgs`, `useUserPackages`); there are no `homeConfigurations`.
- **`modules/system/shared.nix` is required by every host.** It defines the
  `allowedUnfreePackages` option that other bricks set, and must only use
  options that exist on both NixOS and nix-darwin. sops-nix is wired per
  platform in `flake.nix` (`sops-nix.nixosModules.sops` /
  `sops-nix.darwinModules.sops`).
- **Hardware and host-only overrides stay in `hosts/<name>/default.nix`**
  (bus IDs, driver versions, mounts, hostnames, state versions).
- Every `.nix` file except `hardware-configuration.nix` starts with a
  one-line header: `# Scope: <scope> | Used by: <hosts>` (or `| Host: <host>`).
  Update `Used by` when a host starts or stops importing a module.
- Unfree packages are allowed only by name: add them to
  `allowedUnfreePackages` in the brick that uses them. Never set
  `nixpkgs.config.allowUnfree*` directly; definitions would conflict.
- Self-contained features get their own brick (see `nvidia.nix`). Bricks set
  defaults with `lib.mkDefault` where a host might reasonably override them.

## Brick catalog

Every brick in `modules/`. A host is composed by picking rows: system bricks
go in the host's `imports`, home bricks in `home-manager.users.altf4.imports`.
"Any" means it evaluates on both NixOS and nix-darwin. Keep this table, the
bricks' `Used by` headers and the README layout in sync.

| Brick | Platform | Provides | Used by |
|---|---|---|---|
| `system/shared.nix` | Any (required) | `allowedUnfreePackages` option, flakes, sops defaults, timezone, fish as login shell | mercury, saturn |
| `system/fonts.nix` | Any | GeistMono Nerd Font | mercury, saturn |
| `system/nixos-base.nix` | NixOS (required) | boot, nix gc, user, NetworkManager, Tailscale, nix-ld, base packages | saturn |
| `system/server.nix` | NixOS | headless server: OpenSSH (keys only) | saturn |
| `system/nvidia.nix` | NixOS | NVIDIA driver + PRIME offload; host sets bus IDs | saturn |
| `system/apps/t3code-server.nix` | NixOS | T3 Code server only, `t3` with T3 Connect, for headless hosts: official prebuilt x86_64 release run via nix-ld, plus a `t3code` boot service as altf4 and nixpkgs `cloudflared` as its T3 Connect relay client (bump `version` + hash to update) | saturn |
| `system/apps/t3code-appimage.nix` | NixOS | T3 Code desktop app with T3 Connect, for GUI hosts (official prebuilt x86_64 AppImage; bump `version` + hash to update) | none yet (planned: venus) |
| `system/apps/antigravity-cli.nix` | Any | Antigravity CLI, Google's terminal coding agent (`agy`) | mercury, saturn |
| `system/apps/grok-build.nix` | Any | Grok Build, xAI's coding agent CLI (`grok`) | mercury, saturn |
| `system/services/caddy.nix` | NixOS | Caddy with the Cloudflare DNS plugin: wildcard cert for `*.<homeProxy.domain>`, routes from `homeProxy.routes`, ports 80/443 on `tailscale0` only; needs secret `cloudflare_api_token` | saturn |
| `system/services/media.nix` | NixOS | `media` group (gid 2000) and `media.dataDir` (`/data`); the host mounts it | saturn |
| `system/services/jellyfin.nix` | NixOS | Jellyfin at `jellyfin.<domain>`, library read-only | saturn |
| `system/services/qbittorrent.nix` | NixOS | qBittorrent at `qbittorrent.<domain>`, peer port 6881 open | saturn |
| `system/services/prowlarr.nix` | NixOS | Prowlarr at `prowlarr.<domain>` | saturn |
| `system/services/flaresolverr.nix` | NixOS | FlareSolverr on `localhost:8191` (no route) | saturn |
| `system/services/sonarr.nix` | NixOS | Sonarr at `sonarr.<domain>` | saturn |
| `system/services/radarr.nix` | NixOS | Radarr at `radarr.<domain>` | saturn |
| `system/services/lidarr.nix` | NixOS | Lidarr at `lidarr.<domain>` | saturn |
| `system/services/bazarr.nix` | NixOS | Bazarr at `bazarr.<domain>` | saturn |
| `system/services/seerr.nix` | NixOS | Seerr at `seerr.<domain>` | saturn |
| `system/services/slskd.nix` | NixOS | slskd (Podman container, configured in its web UI) at `slskd.<domain>`, port 50300 open | saturn |
| `system/services/soularr.nix` | NixOS | Soularr (Podman container, no UI): Lidarr wanted albums from slskd; starts once `/var/lib/soularr/config.ini` exists | saturn |
| `system/services/beszel.nix` | NixOS | Beszel hub at `beszel.<domain>`: CPU, memory, disk, network, GPU and container history and alerts | saturn |
| `system/services/beszel-agent.nix` | NixOS | Beszel agent (NVIDIA GPU, Podman containers, systemd units); starts once the host sets `services.beszel.agent.environment.KEY`; port 45876 on `tailscale0` | saturn |
| `system/services/scrutiny.nix` | NixOS | Scrutiny at `scrutiny.<domain>`: SMART disk health (InfluxDB on localhost) | saturn |
| `system/services/homepage.nix` | NixOS | Homepage at `homepage.<domain>`: a tile and up/down check per `homeProxy.routes` entry, live stats only where no API key is needed (Scrutiny), plus CPU, memory and disk | saturn |
| `system/darwin-base.nix` | macOS (required) | primary user, nix gc, sops key path, Homebrew | mercury |
| `system/mac-defaults.nix` | macOS | `system.defaults`: Dock, trackpad, keyboard, menu bar, lock; applied without logout | mercury |
| `system/apps/obsidian.nix` | Any | Obsidian | mercury |
| `system/apps/slack.nix` | Any | Slack | mercury |
| `system/apps/spotify.nix` | Any | Spotify | mercury |
| `system/apps/zoom.nix` | Any | Zoom | mercury |
| `system/apps/1password.nix` | macOS | 1Password (cask) | mercury |
| `system/apps/betterdisplay.nix` | macOS | BetterDisplay | mercury |
| `system/apps/t3code-cask.nix` | macOS | T3 Code desktop app with T3 Connect (official cask, updates itself) | mercury |
| `system/apps/cmux.nix` | macOS | cmux | mercury |
| `system/apps/ghostty.nix` | macOS | Ghostty (`ghostty-bin`; nixpkgs `ghostty` is Linux-only) | mercury |
| `system/apps/grok-bot.nix` | macOS | Grok Bot (cask) | mercury |
| `system/apps/helium-browser.nix` | macOS | Helium browser (cask) | mercury |
| `system/apps/hex.nix` | macOS | Hex voice dictation (cask) | mercury |
| `system/apps/local.nix` | macOS | Local (cask) | mercury |
| `system/apps/orbstack.nix` | macOS | OrbStack | mercury |
| `system/apps/raycast.nix` | macOS | Raycast (cask) | mercury |
| `system/apps/tablepro.nix` | macOS | TablePro (cask) | mercury |
| `system/apps/tailscale-app.nix` | macOS | Tailscale app (cask) | mercury |
| `system/apps/velja.nix` | macOS | Velja (App Store, via `mas`) | mercury |
| `system/apps/vorssaint.nix` | macOS | Vorssaint (cask) | mercury |
| `system/apps/vscode.nix` | macOS | VS Code, `code` on the default PATH | mercury |
| `home/shell.nix` | Any | fish, starship, zoxide (`cd`), direnv, eza, neovim as `$EDITOR` | mercury, saturn |
| `home/git.nix` | Any | git + gh, SSH commit signing and GitHub SSH with the sops key | mercury, saturn |
| `home/dev.nix` | Any | CLI tools, Node (fnm), Python (uv), Bun, pnpm, PHP | mercury, saturn |
| `home/claude-code.nix` | Any | Claude Code + `settings.json` | mercury, saturn |
| `home/opencode.nix` | Any | OpenCode + settings, `oc` alias | mercury, saturn |
| `home/mac-user.nix` | macOS | Mac PATHs, sops/age CLIs, `~/Life` folders | mercury |
| `home/mac-wallpaper.nix` | macOS | desktop wallpaper from `assets/wallpapers/` | mercury |
| `home/apps/t3code.nix` | Any | T3 Code settings merged into `~/.t3/userdata` on every switch | mercury, saturn |
| `home/apps/ghostty.nix` | Any | Ghostty config (`package = mkDefault null`) | mercury, saturn |
| `home/apps/1password.nix` | macOS | SSH through the 1Password agent (GitHub excluded) | mercury |
| `home/apps/orbstack.nix` | macOS | OrbStack fish init and SSH include | mercury |
| `home/apps/cmux.nix` | macOS | cmux config | mercury |
| `home/apps/hex.nix` | macOS | Hex settings merged into its `settings.json` on every switch | mercury |
| `home/apps/vorssaint.nix` | macOS | Vorssaint settings, reapplied at app launch | mercury |

## Where to put new things

- Fits an existing brick's "Provides"? Add it there.
- A GUI app? Add `modules/system/apps/<app>.nix` (and
  `modules/home/apps/<app>.nix` if it has config), a catalog row each, and
  import them from each host that wants it.
- A new self-contained feature (an app plus its config, a service, a
  driver)? Make a new brick, add a catalog row, import it from each host
  that wants it. Prefer one brick per feature over growing a catch-all.
- Prefer platform-neutral bricks. Put platform-only bits in a separate brick
  rather than branching on the platform inside one.
- A server service? Add `modules/system/services/<name>.nix` with its
  `homeProxy.routes` entry, a catalog row, and import it from the host.
- Hardware, mounts, keys, bus IDs, hostnames and one-host-only settings go in
  `hosts/<name>/default.nix`.
- Secrets go in `secrets/*.yaml` via sops; reference
  `config.sops.secrets.<name>.path`.
- Anything Nix can't do (sign-ins, app-only settings, permissions) goes in
  that host's guide, `docs/<host>.md`. New how-tos go in `docs/` and get a
  row in the README's Docs table. The README stays an overview (contents,
  ideology, layout): no step-by-step instructions there. Keep the README's
  "What's in it", the docs and this file in sync when adding or removing
  apps, services or hosts.
- Future Linux desktop / gaming: new bricks, e.g. `system/desktop.nix`,
  `system/gaming.nix`, `home/desktop.nix`. Ghostty on Linux needs the
  `ghostty` package instead of `ghostty-bin`. T3 Code: `t3code-cask.nix` on
  Macs, `t3code-appimage.nix` on Linux desktops, `t3code-server.nix` on
  headless servers; pair each with `home/apps/t3code.nix`.

Before moving a Mac package to nixpkgs, check that cache.nixos.org has it for
`aarch64-darwin` (e.g. the Mac uses `ghostty-bin`; plain `ghostty` doesn't build there).

## Adding a host (e.g. `venus`)

1. `mkdir hosts/venus`. For NixOS, generate `hardware-configuration.nix` with
   `nixos-generate-config --no-filesystems`, and write `disko.nix` pointing
   at that machine's `/dev/disk/by-id/...`.
2. Write `hosts/venus/default.nix` with a scope header. List the
   `imports` (`./hardware-configuration.nix`, `./disko.nix`,
   `../../modules/system/shared.nix`, `nixos-base.nix`, then whatever the
   brick catalog offers, e.g. `fonts.nix`, `nvidia.nix`, new desktop/gaming
   bricks), and set `networking.hostName` and `system.stateVersion`. Set
   `home-manager.users.altf4 = { imports = [ ../../modules/home/shell.nix
   ../../modules/home/git.nix ../../modules/home/dev.nix ... ];
   home.stateVersion = "..."; }`.
3. NVIDIA on an RTX 4060: the brick's defaults (open modules, `stable`
   driver, PRIME offload) already fit. Only set
   `hardware.nvidia.prime.{intelBusId,nvidiaBusId}` (or `amdgpuBusId`).
4. In `flake.nix`, add `nixosConfigurations.venus = mkNixos "venus";`
   (`checks` picks it up automatically) and add an `eval-all` line in the
   `justfile`.
5. Add the host's age key to `.sops.yaml` and run
   `sops updatekeys secrets/common.yaml` (see `docs/secrets.md`).
6. Update `Used by` headers in every brick the host imports, the brick
   catalog, the machine table above, the README and `docs/` (add
   `docs/<host>.md`).
7. `git add` the new files, then run the verification commands below.

## Verification (after every edit)

```bash
git add -A                     # flakes only see tracked files
just fmt                       # nix fmt (nixfmt-tree)
just check                     # nix flake check --no-build --all-systems
just eval-all                  # both hosts' drvPaths, from either OS
just dry-build-saturn          # on saturn; just build-mercury on mercury
```

For a pure refactor, compare `just eval-all` output before and after; it
should not change. Moving definitions between files or reordering imports can
reorder merged lists (packages, fish init, Brewfile lines), which changes
drvPaths without changing behavior. If that happens, compare the evaluated
option values with ordering ignored.

## Hard rules

- **Never touch the NTFS data disk.** It's the HDD labelled `ScoobyDoo`
  (UUID `6CA2C4DCA2C4AC40`, currently `sda2`) and it holds irreplaceable data.
  Never add it to `disko.nix`, never format, partition, `wipefs` or `fsck -y`
  it, and never mount it read-write without the owner's explicit approval. It
  is mounted read-write with ntfs-3g (approved by the owner for the media
  stack) only at root-only `/srv/scoobydoo/disk`; `/mnt/data` is a
  read-only bind of the whole disk and `/data` a read-write bind of just its
  `data/` folder. Never widen what is writable or bind other folders
  read-write without approval, and never force-mount it if ntfs-3g refuses
  (hibernated or unclean volume).
- **disko is destructive.** `--mode destroy,format,mount` (or `disko` /
  `disko-install`) erases every disk in `hosts/*/disko.nix`. Only run it when
  the owner asks for a reinstall. To re-mount an existing install, use
  `--mode mount`.
- **Never edit `hardware-configuration.nix` or `disko.nix`** unless asked.
  `hardware-configuration.nix` is generated with `--no-filesystems` because
  disko provides `fileSystems`.
- **No plaintext secrets in Nix files.** Everything in the config ends up in
  the world-readable `/nix/store`. Put secrets in `secrets/` with sops and
  reference them by path. Public SSH keys are fine.
- **Don't change `system.stateVersion` or `home.stateVersion`** once a host
  is installed. They record the install release, not the running version.
- **Commits:** small and focused, a short summary line and a body that
  explains why. Keep comments minimal: only safety warnings and non-obvious
  hardware workarounds, in one line.

## Hardware gotchas

- **nouveau deadlock (saturn):** the HDMI port is on the GTX 1060, so nouveau
  drives the console. If the GPU runtime-suspends and is later woken, nouveau
  deadlocks while holding the console lock, and anything touching a TTY
  hangs. `nouveau.runpm=0` (in `hosts/saturn/default.nix`) prevents this. It's
  only applied when the `nvidia` video driver isn't used. Keep it for whenever
  nouveau is in use. On a live installer without that parameter, avoid
  `lspci` or other PCI probing.
- **NVIDIA (saturn):** the GTX 1060 is Pascal. `hosts/saturn/default.nix`
  overrides the brick with `hardware.nvidia.open = false` and
  `nvidiaPackages.legacy_580`, because newer driver series and CUDA 13 dropped
  Pascal. PRIME bus IDs: Intel `PCI:0:2:0`, NVIDIA `PCI:1:0:0`.
- **Firmware screens aren't visible on saturn.** The BIOS and boot menu
  can't be seen, so changes that need interaction at boot aren't an option.

## Remote access

- mercury is the Mac this repo is usually edited on. Don't run
  `darwin-rebuild` or change its Homebrew setup without the owner asking.
  Nix may not be installed on it, so evaluate on saturn if needed.
- saturn: `ssh altf4@192.168.0.69` (key auth, `PermitRootLogin no`). `sudo`
  needs a password, so run commands that need root interactively, or ask
  the owner. saturn's login shell is fish, so wrap POSIX snippets in
  `bash -c`.
- Long-running jobs over SSH (installs, big builds): run them under
  `systemd-run` with output to a log file, so a dropped connection doesn't
  kill them.

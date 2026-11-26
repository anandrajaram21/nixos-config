<img src="assets/icon.svg" width="64" height="64" alt="">

# nixos-config

Declarative configuration for my machines, built with
[flakes](https://nixos.wiki/wiki/Flakes),
[Home Manager](https://github.com/nix-community/home-manager),
[nix-darwin](https://github.com/nix-darwin/nix-darwin) and
[disko](https://github.com/nix-community/disko). Shared settings are flat,
self-contained bricks in `modules/`, and each host lists the bricks it uses.

| Host | Kind | Platform |
|---|---|---|
| `saturn` | Headless home server | NixOS, `x86_64-linux` |
| `mercury` | Laptop | macOS with nix-darwin, `aarch64-darwin` |

## Layout

```
.
├── flake.nix                          # inputs, mkNixos/mkDarwin (embedded Home Manager), hosts, checks, formatter
├── flake.lock                         # pinned input revisions
├── justfile                           # check / eval-all / build / switch / fmt / update recipes
├── .sops.yaml                         # which age keys can decrypt secrets/
├── secrets/
│   └── common.yaml                    # sops-encrypted secrets
├── modules/                           # database of bricks; bricks never import each other
│   ├── system/
│   │   ├── shared.nix                 # every host (required): unfree list, sops, nix, timezone, fish
│   │   ├── fonts.nix                  # every host: GeistMono Nerd Font
│   │   ├── nixos-base.nix             # every NixOS host: boot, nix gc, user, tailscale, base packages
│   │   ├── server.nix                 # headless servers: OpenSSH
│   │   ├── nvidia.nix                 # NVIDIA driver + PRIME offload; defaults suit Turing and newer
│   │   ├── darwin-base.nix            # every Mac: primary user, nix gc, sops key, Homebrew
│   │   ├── mac-defaults.nix           # every Mac: Dock, trackpad, keyboard, menu bar, lock
│   │   └── apps/                      # one brick per app; each installs it (nixpkgs, cask or App Store)
│   │       ├── t3code-cask.nix        # Mac: T3 Code app (official cask, updates itself)
│   │       ├── t3code-server.nix      # headless NixOS: T3 Code server `t3` (official prebuilt release)
│   │       ├── obsidian.nix, slack.nix, spotify.nix, zoom.nix   # cross-OS, used on the Mac
│   │       └── 1password.nix, betterdisplay.nix, cmux.nix, ghostty.nix, grok-bot.nix,
│   │           helium-browser.nix, local.nix, orbstack.nix, raycast.nix, tablepro.nix,
│   │           tailscale-app.nix, velja.nix, vorssaint.nix, vscode.nix   # Mac-only
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
│           ├── 1password.nix          # Mac: SSH through the 1Password agent
│           ├── orbstack.nix           # Mac: OrbStack shell init and SSH config
│           ├── cmux.nix               # Mac: cmux config
│           └── vorssaint.nix          # Mac: Vorssaint settings
├── hosts/
│   ├── mercury/default.nix            # imports + hostname, stateVersions
│   └── saturn/
│       ├── default.nix                # imports + GTX 1060 overrides, keys, mounts, stateVersions
│       ├── hardware-configuration.nix # generated with --no-filesystems
│       └── disko.nix                  # SSD partition layout (also generates fileSystems)
├── scripts/mac-setup.sh             # fresh-Mac bootstrap: Homebrew, Nix, age key, first switch
├── assets/                          # icon.svg, wallpapers/
└── AGENTS.md                          # notes for AI coding agents (CLAUDE.md links here)
```

Each host's `default.nix` is its explicit list of system bricks (`imports`)
and Home Manager bricks (`home-manager.users.altf4.imports`), plus anything
specific to that machine. Put each setting in the most general brick where
it's valid. Machine-specific hardware and overrides stay in the host file.
`AGENTS.md` has a catalog of every brick and where new things go.

| Input | Tracks | Why |
|---|---|---|
| `nixpkgs` | `nixos-unstable` | Packages and NixOS modules (rolling) |
| `home-manager` | `master` | User-level config; follows our `nixpkgs` |
| `disko` | `master` | Declarative partitioning; follows our `nixpkgs` |
| `sops-nix` | `master` | Encrypted secrets; follows our `nixpkgs` |
| `nix-darwin` | `master` | macOS system config; follows our `nixpkgs` |

## Hardware: saturn

Laptop board running headless, managed over SSH.

| Part | Details |
|---|---|
| CPU | Intel Core i7-8750H (UHD 630 iGPU) |
| dGPU | NVIDIA GTX 1060 Mobile (Pascal). The HDMI port is wired to it. |
| System disk | Intel NVMe 256 GB (`nvme0n1`), managed by disko |
| Data disk | NTFS HDD labelled `ScoobyDoo`, mounted read-only at `/mnt/data` |
| Boot | UEFI, systemd-boot |

The built-in panel has been removed, and firmware screens (BIOS, boot menu) don't
show on HDMI. The Linux console appears on HDMI once the kernel loads.

## Everyday use: saturn

Run these on saturn from a clone of this repo (`~/nixos-config`):

```bash
# Apply config changes
sudo nixos-rebuild switch --flake .#saturn

# Build and activate on next boot only
sudo nixos-rebuild boot --flake .#saturn

# Update all inputs, then rebuild
nix flake update
sudo nixos-rebuild switch --flake .#saturn

# Roll back to the previous generation
sudo nixos-rebuild switch --rollback

# List generations / delete old ones (also runs weekly, keeping 30 days)
nixos-rebuild list-generations
sudo nix-collect-garbage --delete-older-than 30d
```

Flakes only see files tracked by git. `git add` new files before you rebuild,
or Nix reports that the path doesn't exist.

Before committing, format and check that every host still evaluates:

```bash
just fmt        # nix fmt
just check      # nix flake check --no-build --all-systems: evaluates saturn and mercury
just eval-all   # prints both hosts' drvPaths
```

Vorssaint's settings are pinned in `modules/home/apps/vorssaint.nix` and reapplied
at every app launch. To keep a change made in its UI, run `just vorssaint-sync`
(quits the app, exports, rewrites changed values), then `just switch-mercury`
and relaunch Vorssaint.

Without `--all-systems`, `nix flake check` only checks hosts for the machine's
own platform. Dropping `--no-build` builds them, which only works for that
platform.

Every rebuild creates a new generation in the systemd-boot menu (the last 10
are kept). If a change breaks booting, choose an older generation at boot. On
saturn you can't see that menu, so either run `sudo nixos-rebuild switch
--rollback` over SSH, or pick the entry for the next boot with
`sudo bootctl set-oneshot <entry>.conf`.

## Fresh install: saturn

From the NixOS minimal ISO, booted in UEFI mode:

```bash
# 0. Get a copy of this repo onto the installer (git clone, or scp from another machine)
cd nixos-config

# 1. Partition, format and mount the SSD at /mnt. THIS ERASES the disk in disko.nix.
sudo nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko -- --mode destroy,format,mount --flake .#saturn

# 2. Install the system and bootloader
sudo nixos-install --flake .#saturn --no-root-passwd

# 3. Set the user password (needed for sudo; SSH uses keys)
sudo nixos-enter --root /mnt -c 'passwd altf4'

# 4. Remove the USB stick and reboot
```

After the first boot, over SSH:

1. **Secrets:** the new install has a new SSH host key, so sops can't decrypt
   yet. Update saturn's age key in `.sops.yaml` and re-encrypt (see
   [Secrets](#secrets)), then rebuild.
2. **Tailscale:** run `sudo tailscale up` and open the login link it prints.
3. **GitHub CLI and agents:** run `gh auth login`, and sign in to Claude Code
   and OpenCode.

Use disko's `--flake` mode as shown. The plain-file mode evaluates against the
installer's channel and can stall for a long time downloading dependencies.

To re-mount an already-partitioned disk without wiping it, run
`--mode mount` instead of `destroy,format,mount`.

## Known issues: saturn

### nouveau deadlocks on GPU wake-up

With `nouveau`, the GTX 1060 drives the console over HDMI. Something powers
the GPU down, such as switching the monitor to another input. When the GPU is
woken again, nouveau's runtime-resume path re-commits the console display and
waits on the same resume that is still in progress. That's a self-deadlock
while holding the console lock. Everything that touches a TTY then hangs: the
console, `sudo` on the console, systemd units and Nix builds (they open a pty).

- **Installed system:** `boot.kernelParams = [ "nouveau.runpm=0" ]` stops the
  GPU from runtime-suspending at all. It's only set when nouveau is in use,
  i.e. when `modules/system/nvidia.nix` isn't imported.
- **Installer:** while the console is still visible, run
  `echo on | sudo tee /sys/bus/pci/devices/0000:01:00.0/power/control`
  before switching inputs or running anything that probes PCI devices (`lspci`).
- Once stuck, D-state processes can't be killed, so reboot (`echo b > /proc/sysrq-trigger`).

### Slow downloads from cache.nixos.org

Some Fastly edges are sometimes slow from this network. If an install or
rebuild stalls on `copying path ... from 'https://cache.nixos.org'`, restart
it. Completed paths are kept, and a new connection usually lands on a
faster edge.

## NVIDIA driver: saturn

`modules/system/nvidia.nix` is imported from `hosts/saturn/default.nix` and
replaces nouveau. After a rebuild (which builds the kernel module locally),
reboot and check with `nvidia-smi`.

Unfree packages must be listed by name in `allowedUnfreePackages` (defined
in `modules/system/shared.nix`). `nvidia.nix` lists the driver's; add others
there (e.g. CUDA) when needed.

The brick defaults to the open kernel modules and the `stable` driver, which
suit Turing and newer. saturn overrides both in `hosts/saturn/default.nix`
with the proprietary modules (`open = false`) and the `legacy_580` driver. Pascal needs both: the open modules need Turing or newer,
and 580 is the last driver series that supports Pascal. CUDA 13 also dropped
Pascal, so CUDA workloads such as Ollama need a CUDA 12 build.

For media transcoding, the Intel iGPU (Quick Sync, `intel-media-driver`)
handles H.264/HEVC and uses far less power than the dGPU.

## mercury

### Fresh setup

On a fresh macOS install, first sign in to the App Store (`mas` can't sign
in for you, so Velja won't install otherwise). Then clone this repo over HTTPS
and run:

```bash
./scripts/mac-setup.sh
```

`scripts/mac-setup.sh` is safe to re-run; it skips steps already done:

1. Installs [Homebrew](https://brew.sh) (nix-darwin runs `brew bundle` but
   doesn't install Homebrew itself).
2. Installs Nix with the official installer, so nix-darwin manages it.
3. Waits for you to download `keys.txt` (the personal age key) from
   1Password into `~/Downloads`, then moves it to
   `~/Library/Application Support/sops/age/keys.txt`. Without it, the GitHub
   key can't be decrypted and git signing won't work.
4. Installs casks whose `.pkg` installers need `sudo` (Tailscale), since
   `brew bundle` can't ask for a password during the switch.
5. Runs the first `darwin-rebuild switch --flake .#mercury` (pass another host name as the
   first argument to override).
6. Makes fish the login shell and switches the repo's remote to SSH.

Everything else (apps, dotfiles, macOS preferences) comes from this repo,
except these manual steps after the first switch:

1. **1Password:** sign in, then turn on Settings → Developer → Use the SSH
   agent. Every SSH host except GitHub authenticates through it
   (`modules/home/apps/1password.nix`).
2. **Tailscale:** open the app and log in.
3. **GitHub CLI:** run `gh auth login`. Git itself already works over SSH with
   the sops key; `gh` needs its own token for the API.
4. **Claude Code, OpenCode, T3 Code:** sign in to each. In T3 Code, also sign
   in to T3 Connect. If other devices should reach its server, switch its
   server exposure to network-accessible in the app; that's stored in
   `~/.t3/userdata/desktop-settings.json` (`serverExposureMode`), which this
   repo doesn't manage.
5. **Other apps** (Raycast, Slack, Spotify, Zoom, Obsidian, OrbStack, …):
   sign in or grant permissions as each one asks on first launch.

T3 Code and Vorssaint settings are pinned in `modules/home/apps/`, and each
switch writes them back over what's on disk. To keep a change made in T3
Code's UI, copy it into `modules/home/apps/t3code.nix` (for Vorssaint, run
`just vorssaint-sync`).

### Everyday use

```bash
# Apply config changes
sudo darwin-rebuild switch --flake .#mercury

# Roll back to the previous generation
sudo darwin-rebuild switch --rollback
```

Prefer nixpkgs, and use Homebrew only for what nixpkgs lacks or can't run
well:

- CLI tools go in `modules/home/dev.nix` (every host) or
  `modules/home/mac-user.nix` (Mac-only).
- Each GUI app gets its own brick in `modules/system/apps/`, which installs it
  (from nixpkgs, adding unfree ones to `allowedUnfreePackages` there, or as a
  Homebrew cask or App Store app), and is imported from the host. If the app
  has config, it goes in a brick of the same name in `modules/home/apps/`.
- Homebrew is for apps missing from nixpkgs or that must live directly in
  `/Applications` (like 1Password), and `mas` for App Store installs.

Before moving a package to nixpkgs, check it's in cache.nixos.org for
`aarch64-darwin`, or is an unfree app that nixpkgs just repackages (those
aren't cached, but only download the vendor's build). For example, plain
`ghostty` doesn't build on darwin, so the Mac uses `ghostty-bin`.

### App permissions after updates

macOS remembers privacy permissions (Screen Recording, Accessibility,
Camera, Microphone, …) by an app's code signature. Apps signed by their
developer keep them across updates. Some nixpkgs apps are only ad-hoc signed:
currently Obsidian, Spotify and Zoom. After an update, macOS sees
them as a new app, and the old permission silently stops working even though
its switch still shows on. Toggling it off and on doesn't fix that. Instead,
remove the app's entry with the **−** button in System Settings → Privacy &
Security and grant it again, or reset it from a terminal and relaunch the app:

```bash
# Find the app's bundle ID, then reset it (or a single service, e.g. ScreenCapture):
defaults read "/Applications/Nix Apps/zoom.us.app/Contents/Info.plist" CFBundleIdentifier
tccutil reset All <bundle-id>
```

Check an app's signature with `codesign -dv "/Applications/Nix Apps/<App>.app"`:
`Signature=adhoc` means it's affected.

GUI apps from nixpkgs update with `nix flake update`, not through their own
updaters. Homebrew packages removed from the list stay installed, because
`homebrew.onActivation.cleanup` is `"none"`. Set it to `"uninstall"` to
make the list authoritative.

## Secrets

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

## Adding another host

`AGENTS.md` has the full checklist. In short:

1. Create `hosts/<name>/default.nix` that imports
   `../../modules/system/shared.nix`, the platform base
   (`nixos-base.nix` or `darwin-base.nix`) and any other bricks. Set
   `system.stateVersion`, and set `home-manager.users.altf4` to import
   home bricks (at least `shell.nix`, `git.nix`, `dev.nix`; plus `mac-user.nix`
   on a Mac; see the brick catalog in `AGENTS.md`) and set
   `home.stateVersion`. For NixOS, add `hardware-configuration.nix` (from
   `nixos-generate-config --no-filesystems`) and `disko.nix` (point `device`
   at that machine's `/dev/disk/by-id/...`). For a Mac, set
   `nixpkgs.hostPlatform`.
2. Add `nixosConfigurations.<name> = mkNixos "<name>";` or
   `darwinConfigurations.<name> = mkDarwin "<name>";` in `flake.nix`. `nix
   flake check` picks it up automatically. Add it to `eval-all` in the
   `justfile`.
3. For a NixOS host, add its age key to `.sops.yaml` (see Secrets).

If Home Manager would overwrite an existing file in your home directory, it
moves it aside to `<file>.hm-backup` instead of failing.

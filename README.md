<img src="assets/icon.svg" width="64" height="64" alt="">

# nixos-config

Declarative configuration for my machines, built with
[flakes](https://nixos.wiki/wiki/Flakes),
[Home Manager](https://github.com/nix-community/home-manager),
[nix-darwin](https://github.com/nix-darwin/nix-darwin) and
[disko](https://github.com/nix-community/disko). Shared settings live in
`modules/` and `home/` so more hosts can be added.

| Host | Kind | Platform |
|---|---|---|
| `saturn` | Headless home server | NixOS, `x86_64-linux` |
| `mercury` | Laptop | macOS with nix-darwin, `aarch64-darwin` |

## Layout

```
.
├── flake.nix                          # inputs, mkNixos/mkDarwin, hosts, checks, formatter
├── flake.lock                         # pinned input revisions
├── .sops.yaml                         # which age keys can decrypt secrets/
├── secrets/
│   └── common.yaml                    # sops-encrypted secrets
├── modules/
│   ├── shared/
│   │   ├── default.nix                # system settings for every host (NixOS and nix-darwin)
│   │   └── sops.nix                   # which secrets each host decrypts
│   ├── nixos/default.nix              # system settings for every NixOS host; imports shared/
│   └── darwin/default.nix             # system settings for every Mac; imports shared/
├── home/                              # Home Manager config for altf4
│   ├── default.nix                    # every host: imports shell.nix and git.nix, CLI tools
│   ├── shell.nix                      # fish, starship, zoxide, direnv, fnm, nvim
│   ├── git.nix                        # git identity, gh, GitHub SSH key, commit signing
│   └── darwin.nix                     # every Mac: PATHs, OrbStack, 1Password SSH agent
├── hosts/
│   ├── mercury/
│   │   ├── configuration.nix          # hostname, stateVersion, imports
│   │   ├── homebrew.nix               # Homebrew formulae, casks and App Store apps
│   │   └── home.nix                   # imports home/ and home/darwin.nix
│   └── saturn/
│       ├── configuration.nix          # host-only system config (hostname, keys, mounts)
│       ├── home.nix                   # imports home/, sets home.stateVersion
│       ├── hardware-configuration.nix # generated with --no-filesystems
│       ├── disko.nix                  # SSD partition layout (also generates fileSystems)
│       └── nvidia.nix                 # NVIDIA driver module
├── assets/icon.svg
└── AGENTS.md                          # notes for AI coding agents
```

Put each setting in the most general place where it's valid:

- `modules/shared/`: every host, using only options nix-darwin also has.
- `modules/nixos/` or `modules/darwin/`: every host on that platform.
- `home/`: every host's Home Manager config. `home/darwin.nix` is for Macs only.
- `hosts/<host>/`: that machine only. Its `configuration.nix` imports
  `modules/nixos` or `modules/darwin`, and its `home.nix` imports `home/`.

A self-contained feature goes in its own file (like `nvidia.nix`), imported
where it's needed.

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
nix fmt
nix flake check --no-build --all-systems   # evaluates saturn and mercury
```

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
  i.e. when `nvidia.nix` isn't imported.
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

`hosts/saturn/nvidia.nix` is imported from `configuration.nix` and replaces
nouveau. After a rebuild (which builds the kernel module locally), reboot and
check with `nvidia-smi`.

Only `nvidia*` packages are allowed to be unfree. Add others to
`allowUnfreePredicate` in `nvidia.nix` (e.g. CUDA) when needed.

The module uses the proprietary kernel modules (`open = false`) and the
`legacy_580` driver. Pascal needs both: the open modules need Turing or newer,
and 580 is the last driver series that supports Pascal. CUDA 13 also dropped
Pascal, so CUDA workloads such as Ollama need a CUDA 12 build.

For media transcoding, the Intel iGPU (Quick Sync, `intel-media-driver`)
handles H.264/HEVC and uses far less power than the dGPU.

## mercury

### Fresh setup

On a fresh macOS install:

1. Install Nix with the official installer, so nix-darwin manages it:
   `sh <(curl -L https://nixos.org/nix/install)`.
2. Install [Homebrew](https://brew.sh). nix-darwin runs `brew bundle` but
   doesn't install Homebrew itself.
3. Restore the personal age key to
   `~/Library/Application Support/sops/age/keys.txt` from its backup. Without
   it, the GitHub key can't be decrypted and git signing won't work.
4. Clone this repo (over HTTPS, since the SSH key isn't set up yet) and run
   the first switch:

   ```bash
   sudo nix --extra-experimental-features "nix-command flakes" \
     run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#mercury
   ```

5. Make fish the login shell: `chsh -s /run/current-system/sw/bin/fish`.
6. Restore the remaining dotfiles with yadm, minus anything this repo now
   manages (see below).

Home Manager owns fish, git, ssh and starship on mercury. yadm still holds
other dotfiles (Ghostty, OpenCode, Claude, ...), but must not track
`.config/fish/config.fish` or `.config/fish/conf.d/{fnm,uv}.fish`, and its
Homebrew and shell bootstrap scripts are replaced by `hosts/mercury/`.

### Everyday use

```bash
# Apply config changes
sudo darwin-rebuild switch --flake .#mercury

# Roll back to the previous generation
sudo darwin-rebuild switch --rollback
```

Homebrew packages are declared in `hosts/mercury/homebrew.nix`. Packages
removed from that list stay installed, because
`homebrew.onActivation.cleanup` is `"none"`. Set it to `"uninstall"` to
make the list authoritative. CLI tools that every host should have go in
`home/` instead, from nixpkgs.

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

`modules/shared/sops.nix` declares the common secrets. A host-only secret goes
in that host's directory with `sopsFile = ../../secrets/<host>.yaml;`.

| Secret | File | Used for |
|---|---|---|
| `github_ssh_key` | `common.yaml` | GitHub SSH auth and commit signing for altf4 |

```bash
# Edit secrets (on a Mac; home/darwin.nix installs sops and age)
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

1. Create `hosts/<name>/configuration.nix` that imports `../../modules/nixos`
   or `../../modules/darwin` and sets `system.stateVersion`. For NixOS, add
   `hardware-configuration.nix` (from `nixos-generate-config
   --no-filesystems`) and `disko.nix` (point `device` at that machine's
   `/dev/disk/by-id/...`). For a Mac, set `nixpkgs.hostPlatform`.
2. Create `hosts/<name>/home.nix` that imports `../../home` (and
   `../../home/darwin.nix` on a Mac) and sets `home.stateVersion`.
3. Add `nixosConfigurations.<name> = mkNixos "<name>";` or
   `darwinConfigurations.<name> = mkDarwin "<name>";` in `flake.nix`. `nix
   flake check` picks it up automatically.
4. For a NixOS host, add its age key to `.sops.yaml` (see Secrets).

If Home Manager would overwrite an existing file in your home directory, it
moves it aside to `<file>.hm-backup` instead of failing.

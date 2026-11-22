<img src="assets/icon.svg" width="64" height="64" alt="">

# nixos-config

Declarative NixOS configuration for **saturn**, a home server, built with
[flakes](https://nixos.wiki/wiki/Flakes),
[Home Manager](https://github.com/nix-community/home-manager) and
[disko](https://github.com/nix-community/disko). Shared settings live in
`common.nix` files so more hosts can be added.

## Layout

```
.
├── flake.nix                          # inputs + nixosConfigurations.saturn
├── flake.lock                         # pinned input revisions
├── .sops.yaml                         # which age keys can decrypt secrets/
├── secrets/
│   └── common.yaml                    # sops-encrypted secrets
├── modules/
│   └── common.nix                     # system settings shared by every host
├── home/
│   └── common.nix                     # Home Manager config for altf4 shared by every host
└── hosts/
    └── saturn/
        ├── configuration.nix          # system config (boot, network, users, SSH, mounts)
        ├── home.nix                   # Home Manager config for altf4 on saturn
        ├── hardware-configuration.nix # generated with --no-filesystems
        ├── disko.nix                  # SSD partition layout (also generates fileSystems)
        ├── nvidia.nix                 # NVIDIA driver module
        └── sops.nix                   # secrets decrypted on saturn
```

Everything specific to a host lives in `hosts/<host>/`. Its
`configuration.nix` imports `modules/common.nix`, and its `home.nix` imports
`home/common.nix`. Put a setting in a `common.nix`
file when every host should have it, and in the host file otherwise.

| Input | Tracks | Why |
|---|---|---|
| `nixpkgs` | `nixos-unstable` | Packages and NixOS modules (rolling) |
| `home-manager` | `master` | User-level config; follows our `nixpkgs` |
| `disko` | `master` | Declarative partitioning; follows our `nixpkgs` |
| `sops-nix` | `master` | Encrypted secrets; follows our `nixpkgs` |

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

## Everyday use

Run these on saturn from a clone of this repo (`~/nixos-config`):

```bash
# Apply config changes
sudo nixos-rebuild switch --flake .#saturn

# Build and activate on next boot only
sudo nixos-rebuild boot --flake .#saturn

# Update all inputs (nixpkgs, home-manager, disko, sops-nix), then rebuild
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
nix flake check --no-build   # drop --no-build to build every host
```

Every rebuild creates a new generation in the systemd-boot menu (the last 10
are kept). If a change breaks booting, choose an older generation at boot. On
saturn you can't see that menu, so either run `sudo nixos-rebuild switch
--rollback` over SSH, or pick the entry for the next boot with
`sudo bootctl set-oneshot <entry>.conf`.

## Fresh install

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

## Known issues

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

## Secrets

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and
committed in `secrets/`. `.sops.yaml` lists who can decrypt them:

- `altf4`: an age key on the Mac at
  `~/Library/Application Support/sops/age/keys.txt`, used to edit secrets.
  Keep a backup of it.
- `saturn`: derived from saturn's SSH host key, used at boot and on rebuild
  to decrypt into `/run/secrets/`.

| Secret | Used for |
|---|---|
| `github_ssh_key` | GitHub SSH auth and commit signing for altf4 |

```bash
# Edit secrets (on the Mac; needs `brew install sops age`)
sops secrets/common.yaml

# After adding a host or key to .sops.yaml, re-encrypt for the new recipients
sops updatekeys secrets/common.yaml
```

A new host's age key comes from its SSH host key:
`nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub`.
After a reinstall, saturn gets a new host key, so update its entry in
`.sops.yaml` and run `sops updatekeys` before rebuilding.

## NVIDIA driver

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

## Adding another host

1. Create `hosts/<name>/configuration.nix` that imports `../../modules/common.nix`.
   For NixOS, add `hardware-configuration.nix` (from
   `nixos-generate-config --no-filesystems`) and `disko.nix` (point `device`
   at that machine's `/dev/disk/by-id/...`).
2. Create `hosts/<name>/home.nix` that imports `../../home/common.nix` and sets
   `home.stateVersion`.
3. Add `nixosConfigurations.<name>` in `flake.nix`, using
   `homeManagerFor ./hosts/<name>/home.nix`.

For a Mac, add a `nix-darwin` input and a `darwinConfigurations.<name>` that
uses `home-manager.darwinModules.home-manager`. `modules/common.nix` only uses
options nix-darwin also has, so it can be imported there too.

# AGENTS.md

Guidance for AI coding agents working in this repo. Read `README.md` for the
layout and everyday commands.

## What this is

A NixOS flake, currently with one host, `saturn` (a headless home server),
with Home Manager as a NixOS module and disko for partitioning. Shared
settings are split out so more hosts (including a nix-darwin Mac) can be
added. Inputs track `nixos-unstable`, and `flake.lock` pins them.

## Hard rules

- **Never touch the NTFS data disk.** It's the HDD labelled `ScoobyDoo`
  (UUID `6CA2C4DCA2C4AC40`, currently `sda2`) and it holds irreplaceable data.
  Never add it to `disko.nix`, never format, partition, `wipefs` or `fsck -y`
  it, and never mount it read-write without the owner's explicit approval. It
  is mounted read-only at `/mnt/data` by UUID with `nofail`.
- **disko is destructive.** `--mode destroy,format,mount` (or `disko` /
  `disko-install`) erases every disk in `hosts/*/disko.nix`. Only run it when
  the owner asks for a reinstall. To re-mount an existing install, use
  `--mode mount`.
- **Commits:** Prefer small, focused commits with a short summary line
  and a body that explains why.
- **No plaintext secrets in Nix files.** Everything in the config ends up in
  the world-readable `/nix/store`. Put secrets in `secrets/` with sops (see
  README), and reference them by `config.sops.secrets.<name>.path`. Never
  write decrypted secrets to the repo or the store. Public SSH keys are fine.
- **Don't change `system.stateVersion` or `home.stateVersion`** (`26.05` on
  saturn). They record the install release, not the running version.

## Working on the config

- Flakes only see git-tracked files. `git add` new files before evaluating or
  building, or you'll get "path does not exist".
- Shared settings go in `modules/common.nix` (system) and `home/common.nix`
  (user). Keep `modules/common.nix` to options that also exist in nix-darwin.
- Host-specific settings, system and Home Manager, go in `hosts/<host>/`. New
  features go in their own module file, imported from the host's `imports`
  (see `nvidia.nix`).
- Check every host still evaluates after a change with
  `nix flake check --no-build`. For a pure refactor, compare
  `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
  before and after; it should not change.
- Run `nix fmt` (nixfmt) before committing. Keep comments minimal: only
  safety warnings and non-obvious hardware workarounds, in one line.
- `hardware-configuration.nix` is generated with `--no-filesystems`, because
  disko provides `fileSystems`. Don't add filesystem entries there.

## Hardware gotchas

- **nouveau deadlock:** the HDMI port is on the GTX 1060, so nouveau drives
  the console. If the GPU runtime-suspends and is later woken, nouveau
  deadlocks while holding the console lock, and anything touching a TTY
  hangs. `nouveau.runpm=0` (in `configuration.nix`) prevents this. It's only
  applied when `nvidia.nix` isn't imported, since the NVIDIA driver
  blacklists nouveau. Keep it for whenever nouveau is in use. On a live
  installer without that parameter, avoid `lspci` or other PCI probing.
- **NVIDIA:** the GTX 1060 is Pascal. It needs `hardware.nvidia.open = false`
  and `nvidiaPackages.legacy_580`, because newer driver series and CUDA 13
  dropped Pascal. PRIME bus IDs: Intel `PCI:0:2:0`, NVIDIA `PCI:1:0:0`.
- **Firmware screens aren't visible.** The BIOS and boot menu can't be seen,
  so changes that need interaction at boot aren't an option.

## Remote access

- Installed system: `ssh altf4@192.168.0.69` (key auth, `PermitRootLogin no`).
  `sudo` needs a password, so run commands that need root interactively, or
  ask the owner.
- Long-running jobs over SSH (installs, big builds): run them under
  `systemd-run` with output to a log file, so a dropped connection doesn't
  kill them.

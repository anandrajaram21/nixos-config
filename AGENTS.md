# AGENTS.md

Guidance for AI coding agents working in this repo (`CLAUDE.md` is a symlink
to this file). `README.md` covers installs, secrets and everyday use.

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
modules/home/*.nix        Home Manager bricks for user altf4
```

Rules:

- **Flat module database.** Each file in `modules/` is a standalone brick.
  Modules never import other modules; only `hosts/<name>/default.nix`
  imports modules, and it lists every one explicitly.
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

## Where to put things

| What | Where |
|---|---|
| Option valid on both NixOS and nix-darwin, every host | `modules/system/shared.nix` |
| Every NixOS host (server or desktop) | `modules/system/nixos-base.nix` |
| Every Mac | `modules/system/darwin-base.nix` |
| Headless-server services (sshd, future daemons) | `modules/system/server.nix` |
| NVIDIA driver boilerplate | `modules/system/nvidia.nix` (host sets bus IDs and per-GPU overrides) |
| Mac GUI apps (nixpkgs first, else Homebrew cask / `mas`) | `modules/system/mac-apps.nix` |
| CLI/dev tools, shell, git, editors for every host | `modules/home/dev.nix` |
| Mac-only user config (PATHs, OrbStack, 1Password agent) | `modules/home/mac-user.nix` |
| Future Linux desktop / gaming (DE, Steam, ...) | new bricks, e.g. `modules/system/desktop.nix`, `modules/system/gaming.nix`, `modules/home/desktop.nix` |
| Hardware, mounts, keys, bus IDs, one-host-only settings | `hosts/<name>/default.nix` |
| Secrets | `secrets/*.yaml` via sops; reference `config.sops.secrets.<name>.path` |

Before moving a Mac package to nixpkgs, check that cache.nixos.org has it for
`aarch64-darwin` (e.g. use `firefox-bin`, not `firefox`).

## Adding a host (e.g. `venus`)

1. `mkdir hosts/venus`. For NixOS, generate `hardware-configuration.nix` with
   `nixos-generate-config --no-filesystems`, and write `disko.nix` pointing
   at that machine's `/dev/disk/by-id/...`.
2. Write `hosts/venus/default.nix` with a scope header. List the
   `imports` (`./hardware-configuration.nix`, `./disko.nix`,
   `../../modules/system/shared.nix`, `nixos-base.nix`, `nvidia.nix`, plus any
   new desktop/gaming bricks), and set `networking.hostName` and
   `system.stateVersion`. Set `home-manager.users.altf4 = { imports = [
   ../../modules/home/dev.nix ]; home.stateVersion = "..."; }`.
3. NVIDIA on an RTX 4060: the brick's defaults (open modules, `stable`
   driver, PRIME offload) already fit. Only set
   `hardware.nvidia.prime.{intelBusId,nvidiaBusId}` (or `amdgpuBusId`).
4. In `flake.nix`, add `nixosConfigurations.venus = mkNixos "venus";`
   (`checks` picks it up automatically) and add an `eval-all` line in the
   `justfile`.
5. Add the host's age key to `.sops.yaml` and run
   `sops updatekeys secrets/common.yaml` (see README, Secrets).
6. Update `Used by` headers in every brick the host imports, the machine
   table above and the README.
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
  is mounted read-only at `/mnt/data` by UUID with `nofail`.
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

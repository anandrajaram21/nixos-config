# Adding a host

[← README](../README.md)

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
3. For a NixOS host, add its age key to `.sops.yaml` (see
   [secrets.md](secrets.md)).

If Home Manager would overwrite an existing file in your home directory, it
moves it aside to `<file>.hm-backup` instead of failing.

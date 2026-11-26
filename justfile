# List recipes
default:
    @just --list

# Evaluate every host for every platform (no builds)
check:
    nix flake check --no-build --all-systems

# Print both hosts' system drvPaths; works from either OS
eval-all:
    nix eval --raw .#darwinConfigurations.mercury.system.drvPath && echo
    nix eval --raw .#nixosConfigurations.saturn.config.system.build.toplevel.drvPath && echo

# Build mercury without activating (run on mercury)
build-mercury:
    darwin-rebuild build --flake .#mercury

# Build and activate mercury (run on mercury)
switch-mercury:
    sudo darwin-rebuild switch --flake .#mercury

# Build saturn without activating (run on saturn)
build-saturn:
    nixos-rebuild build --flake .#saturn

# Show what building saturn would fetch or build, without building
dry-build-saturn:
    nixos-rebuild dry-build --flake .#saturn

# Build and activate saturn (run on saturn)
switch-saturn:
    sudo nixos-rebuild switch --flake .#saturn

# Copy apps' UI settings into modules/home/apps (all apps, or some: just sync hex)
sync *apps:
    python3 -I scripts/sync-settings.py {{apps}}
    nix fmt
    git diff --stat -- modules/home/apps

# Format every .nix file with the flake's formatter (nixfmt-tree)
fmt:
    nix fmt

# Update all flake inputs
update:
    nix flake update

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

# Roll mercury back to the previous generation (run on mercury)
rollback-mercury:
    sudo darwin-rebuild switch --rollback

# Build saturn without activating (run on saturn)
build-saturn:
    nixos-rebuild build --flake .#saturn

# Show what building saturn would fetch or build, without building
dry-build-saturn:
    nixos-rebuild dry-build --flake .#saturn

# Build and activate saturn (run on saturn)
switch-saturn:
    sudo nixos-rebuild switch --flake .#saturn

# Build saturn and make it the default on next boot, without activating now (run on saturn)
boot-saturn:
    sudo nixos-rebuild boot --flake .#saturn

# Roll saturn back to the previous generation (run on saturn)
rollback-saturn:
    sudo nixos-rebuild switch --rollback

# Delete generations and store paths older than 30 days (also runs weekly)
gc:
    sudo nix-collect-garbage --delete-older-than 30d

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

# Pin saturn's T3 Code server to the latest nightly release (then switch-saturn)
bump-t3:
    #!/usr/bin/env bash
    set -euo pipefail
    tag=$(gh release list -R pingdotgg/t3code -L 30 --json tagName -q '[.[] | select(.tagName | test("nightly"))][0].tagName')
    version=${tag#v}
    url="https://github.com/pingdotgg/t3code/releases/download/$tag/t3-$version-linux-x64.tar.gz"
    hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
    f=modules/system/apps/t3code-server.nix
    perl -pi -e "s|^  version = \".*\";|  version = \"$version\";|; s|^      hash = \".*\";|      hash = \"$hash\";|" "$f"
    git diff --stat -- "$f"

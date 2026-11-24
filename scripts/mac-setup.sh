#!/bin/bash
# Scope: fresh-Mac bootstrap (Homebrew, Nix, age key, first nix-darwin switch) | Host: mercury
# Usage: ./scripts/mac-setup.sh [host]   (from a clone of this repo)
set -euo pipefail

HOST="${1:-mercury}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY_SRC="$HOME/Downloads/keys.txt"
KEY_DIR="$HOME/Library/Application Support/sops/age"
KEY_DST="$KEY_DIR/keys.txt"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

[ "$(uname -s)" = Darwin ] || { echo "This script is for macOS." >&2; exit 1; }

step "Homebrew"
if [ -x /opt/homebrew/bin/brew ]; then
  echo "Already installed."
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

step "Nix"
if [ -d /nix/store ] && [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  echo "Already installed."
else
  sh <(curl -fsSL https://nixos.org/nix/install)
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

step "sops age key"
if [ -s "$KEY_DST" ]; then
  echo "Already at $KEY_DST."
else
  until [ -s "$KEY_SRC" ]; do
    echo "Download keys.txt from 1Password (e.g. my.1password.com in a browser)"
    echo "and save it as $KEY_SRC."
    read -r -p "Press Enter once it's there... " _
  done
  mkdir -p "$KEY_DIR"
  mv "$KEY_SRC" "$KEY_DST"
  chmod 700 "$KEY_DIR"
  chmod 600 "$KEY_DST"
  echo "Moved to $KEY_DST."
fi

cd "$REPO_DIR"

step "Casks with .pkg installers"
# Their installers need sudo, which brew bundle can't prompt for during the switch.
for cask in tailscale-app; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "$cask already installed."
  else
    brew install --cask "$cask"
  fi
done

step "nix-darwin switch (.#$HOST)"
sudo nix --extra-experimental-features "nix-command flakes" \
  run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake ".#$HOST"

step "Login shell"
FISH=/run/current-system/sw/bin/fish
if dscl . -read "/Users/$USER" UserShell | grep -q "$FISH"; then
  echo "Already fish."
else
  chsh -s "$FISH"
fi

step "Repo remote -> SSH"
git remote set-url origin git@github.com:anandrajaram21/nixos-config.git

step "Done"
echo "Open a new terminal."

# mercury

[← README](../README.md)

Apple Silicon MacBook: nix-darwin, Homebrew and Home Manager.

- [Fresh setup](#fresh-setup)
- [Everyday use](#everyday-use)
- [App settings](#app-settings)
- [Installing apps](#installing-apps)
- [App permissions after updates](#app-permissions-after-updates)

## Fresh setup

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
4. **Claude Code, OpenCode, Grok Build, T3 Code:** sign in to each. In T3 Code, also sign
   in to T3 Connect. If other devices should reach its server, switch its
   server exposure to network-accessible in the app; that's stored in
   `~/.t3/userdata/desktop-settings.json` (`serverExposureMode`), which this
   repo doesn't manage.
5. **Other apps** (Raycast, Hex, Slack, Spotify, Zoom, Obsidian, OrbStack, …):
   sign in or grant permissions as each one asks on first launch.

## Everyday use

```bash
# Apply config changes
sudo darwin-rebuild switch --flake .#mercury

# Roll back to the previous generation
sudo darwin-rebuild switch --rollback
```

## App settings

T3 Code, Hex and Vorssaint settings are pinned in `modules/home/apps/`, and
each switch writes them back over what's on disk (Vorssaint reapplies them at
every launch). To keep changes made in their settings windows, run `just sync`
(or `just sync hex` for one app), review the diff and commit. It quits Hex and
Vorssaint first so they save their settings, rewrites only values the repo
already pins, and lists settings the app has that aren't pinned. To pin another
app's settings, add it to `APPS` in `scripts/sync-settings.py`. Quit Hex before
switching, or it may save its in-memory settings over the merged file.

## Installing apps

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

GUI apps from nixpkgs update with `nix flake update`, not through their own
updaters. Homebrew packages removed from the list stay installed, because
`homebrew.onActivation.cleanup` is `"none"`. Set it to `"uninstall"` to
make the list authoritative.

## App permissions after updates

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

# saturn

[← README](../README.md)

Headless home server: NixOS on an old gaming laptop, managed over SSH.

- [Hardware](#hardware)
- [Everyday use](#everyday-use)
- [Services](#services)
- [Storage](#storage)
- [Fresh install](#fresh-install)
- [NVIDIA driver](#nvidia-driver)
- [Known issues](#known-issues)

## Hardware

| Part | Details |
|---|---|
| CPU | Intel Core i7-8750H (UHD 630 iGPU) |
| dGPU | NVIDIA GTX 1060 Mobile (Pascal). The HDMI port is wired to it. |
| System disk | Intel NVMe 256 GB (`nvme0n1`), managed by disko |
| Data disk | NTFS HDD labelled `ScoobyDoo` (see [Storage](#storage)) |
| Boot | UEFI, systemd-boot |

The built-in panel has been removed, and firmware screens (BIOS, boot menu) don't
show on HDMI. The Linux console appears on HDMI once the kernel loads.

## Everyday use

Run these on saturn from a clone of this repo (`~/nixos-config`); `just`
lists every recipe:

```bash
just switch-saturn     # apply config changes
just boot-saturn       # build now, activate on next boot
just update            # update all inputs (then switch)
just rollback-saturn   # back to the previous generation
just gc                # delete generations older than 30 days (also runs weekly)
```

Flakes only see files tracked by git. `git add` new files before you rebuild,
or Nix reports that the path doesn't exist.

Before committing, format and check that every host still evaluates:

```bash
just fmt        # nix fmt
just check      # evaluates saturn and mercury, for both platforms
just eval-all   # prints both hosts' drvPaths
```

Every rebuild creates a new generation in the systemd-boot menu (the last 10
are kept). If a change breaks booting, choose an older generation at boot. On
saturn you can't see that menu, so either run `just rollback-saturn` over
SSH, or pick the entry for the next boot with
`sudo bootctl set-oneshot <entry>.conf`.

## Services

Each service in `modules/system/services/` gets an HTTPS name,
`<name>.home.anandrajaram.dev`, reachable only over Tailscale:

```text
device on tailnet ─▶ <name>.home.<domain> ─(DNS)─▶ saturn's Tailscale IP:443 ─▶ Caddy ─▶ 127.0.0.1:<port>
```

| Name | Does |
|---|---|
| `jellyfin` | Plays the library; NVENC transcoding on the GTX 1060 |
| `seerr` | Requests for movies and TV |
| `sonarr`, `radarr`, `lidarr` | TV, movies, music: pick releases and import them into the library |
| `prowlarr` | Indexers, shared with the three above (FlareSolverr on `localhost:8191` for Cloudflare) |
| `bazarr` | Subtitles for Sonarr and Radarr |
| `qbittorrent` | Downloads |
| `slskd` | Soulseek client; Soularr (no UI) fills Lidarr's wanted albums from it every 5 minutes |
| `homepage` | Start page: a tile per service with an up/down check, plus CPU, memory and disk |
| `beszel` | CPU, memory, disk, network, GPU and container graphs with history and alerts |
| `scrutiny` | Disk health from SMART, with failure warnings |

- **DNS:** a Cloudflare `A` record `*.home` → saturn's Tailscale IP
  (`tailscale ip -4`, currently `100.95.91.64`), DNS only (grey cloud). The
  `100.x` address only routes inside the tailnet.
- **HTTPS:** Caddy gets one wildcard certificate through a Cloudflare DNS
  challenge (`cloudflare_api_token` in `secrets/saturn.yaml`: an "Edit zone
  DNS" token for this zone only), so nothing needs to be reachable from the
  internet, and the certificate logs don't list individual service names.
  Unknown names get no response. Ports 80/443 are open only on `tailscale0`.
- **Add a service:** a brick in `modules/system/services/` that enables it and
  sets `homeProxy.routes.<name> = <port>;`, imported by the host. The DNS
  record and certificate already cover the new name.
- **Outside Tailscale:** Jellyfin also listens on the LAN at
  `http://192.168.0.69:8096` (plain HTTP) for the TV; add it there by
  address, since autodiscovery doesn't work. qBittorrent's peer port 6881
  (TCP/UDP) and Soulseek's 50300 are open too; they reach the internet only
  if the router forwards them to 192.168.0.69.

Nix only installs and runs the services. Each app's settings (folders,
download clients, connections between apps, logins) are set once in its web
UI and kept under `/var/lib/<app>` on saturn; they only need redoing after a
reinstall. [saturn-media-setup.md](saturn-media-setup.md) walks through every
app in order; [saturn-monitoring.md](saturn-monitoring.md) covers the
monitoring apps.

Check from a tailnet device: `dig +short jellyfin.home.anandrajaram.dev`
returns the Tailscale IP, and `curl -I https://jellyfin.home.anandrajaram.dev`
answers with a valid certificate. Certificate problems show in
`journalctl -u caddy`.

## Storage

The `ScoobyDoo` NTFS disk is mounted once, read-write with ntfs-3g, at
`/srv/scoobydoo/disk` inside a root-only directory, and exposed twice:
`/mnt/data` read-only (the whole disk), and `/data` read-write (only its
`data/` folder, the media tree). Services see only `/data`, and only start
once it's mounted, so a missing disk can't fill the SSD. Jellyfin's view of
`/data` is read-only. Files on the disk are owned by altf4 and group `media`
(group-writable); every media service runs in that group.

```text
/data/
├── torrents/{movies,tv,music}     # qBittorrent downloads
├── slskd/{downloads,incomplete}   # Soulseek downloads
└── media/{movies,tv,music}        # the library Jellyfin reads
```

Downloads and the library are on one filesystem, so Sonarr, Radarr and
Lidarr import with hardlinks: instant, and no space used twice. This follows
the [TRaSH Guides](https://trash-guides.info/File-and-Folder-Structure/)
layout, so their guides apply as written. App databases stay on the SSD under
`/var/lib/<app>`; back that up, it holds every setting.

If Windows left the disk hibernated or unclean, ntfs-3g refuses to mount it
read-write, and `/mnt/data`, `/data` and the media services stay down. Fix it
from Windows (full shutdown, not hibernate) rather than forcing the mount.

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

After the first boot, over SSH:

1. **Secrets:** the new install has a new SSH host key, so sops can't decrypt
   yet. Update saturn's age key in `.sops.yaml` and re-encrypt (see
   [secrets.md](secrets.md)), then rebuild.
2. **Tailscale:** run `sudo tailscale up` and open the login link it prints.
3. **GitHub CLI and agents:** run `gh auth login`, and sign in to Claude Code,
   OpenCode, Grok Build (`grok`) and the Antigravity CLI (`agy`).
4. **Services:** if saturn's Tailscale IP changed, update the `*.home`
   record in Cloudflare, then restore `/var/lib/<app>` from a backup or
   follow [saturn-media-setup.md](saturn-media-setup.md).
5. **T3 Connect:** run `t3 connect link`, open the URL it prints on any
   device and enter the code, then `sudo systemctl restart t3code`. The
   `t3code` service runs the server on boot; `t3 connect status` checks it.

Use disko's `--flake` mode as shown. The plain-file mode evaluates against the
installer's channel and can stall for a long time downloading dependencies.

To re-mount an already-partitioned disk without wiping it, run
`--mode mount` instead of `destroy,format,mount`.

## NVIDIA driver

`modules/system/nvidia.nix` is imported from `hosts/saturn/default.nix` and
replaces nouveau. After a rebuild (which builds the kernel module locally),
reboot and check with `nvidia-smi`.

Unfree packages must be listed by name in `allowedUnfreePackages` (defined
in `modules/system/shared.nix`). `nvidia.nix` lists the driver's; add others
there (e.g. CUDA) when needed.

The brick defaults to the open kernel modules and the `stable` driver, which
suit Turing and newer. saturn overrides both in `hosts/saturn/default.nix`
with the proprietary modules (`open = false`) and the `legacy_580` driver.
Pascal needs both: the open modules need Turing or newer, and 580 is the last
driver series that supports Pascal. CUDA 13 also dropped Pascal, so CUDA
workloads such as Ollama need a CUDA 12 build.

For media transcoding, the Intel iGPU (Quick Sync, `intel-media-driver`)
handles H.264/HEVC and uses far less power than the dGPU.

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

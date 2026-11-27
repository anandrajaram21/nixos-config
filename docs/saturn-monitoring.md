# Monitoring (saturn)

[← saturn](saturn.md#services)

Three apps, each at `https://<name>.home.anandrajaram.dev` on the tailnet:

| App | Shows | Setup |
|---|---|---|
| Homepage (`homepage`) | Start page: a tile per service with a green/red up check, plus CPU, memory, CPU temperature, uptime and disk space for the NVMe and ScoobyDoo. Scrutiny's tile shows drive health counts | None. It's built from `homeProxy.routes`, so a new service brick gets a tile on its own. Widgets that need an app's API key are left out on purpose, so no keys are stored |
| Beszel (`beszel`) | CPU, memory, disk usage and I/O (NVMe and ScoobyDoo, read through `/mnt/data`), network, temperatures, GPU (`nvidia-smi`), Podman containers and systemd units, with history and alerts | Once, below |
| Scrutiny (`scrutiny`) | SMART health for the NVMe and the `ScoobyDoo` HDD, with failure warnings | None. The collector runs daily; the first data shows up after its first run |

Scrutiny and smartd only read SMART data; they never write to a disk.

## Beszel first run

The agent stays off until it knows the hub's public key, so this takes one
extra switch.

1. Open `https://beszel.home.anandrajaram.dev` and create the admin account.
2. **Add System**:
   - Name: `saturn`
   - Host / IP: `127.0.0.1`
   - Port: `45876`
   - Copy the **Public Key**, then **Add System**.
3. In `hosts/saturn/default.nix`, set
   `services.beszel.agent.environment.KEY = "ssh-ed25519 AAAA...";` (it's a
   public key, so it's fine in the repo), then `just switch-saturn`.
4. The system turns green in Beszel within a minute.
5. Optional, **Settings → Notifications**: add an email or webhook target,
   then set alerts per system with the bell icon (e.g. disk above 90%, CPU
   above 90% for 10 minutes, system down).

To watch another NixOS host, import `beszel-agent.nix` there, add it in
Beszel with its Tailscale IP, and set the same `KEY` on it.

## Starting Scrutiny's first scan early

```bash
sudo systemctl start scrutiny-collector
```

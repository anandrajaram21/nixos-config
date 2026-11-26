# Scope: NixOS system (slskd container at slskd.<domain>: Soulseek client, configured in its web UI; port 50300 open for peers) | Used by: saturn
{ config, ... }:

let
  data = config.media.dataDir;
  state = "/var/lib/slskd";
in
{
  virtualisation.podman.enable = true;

  # Container, not the NixOS module: the module's config is read-only, so the web UI couldn't change it.
  virtualisation.oci-containers.containers.slskd = {
    image = "docker.io/slskd/slskd:latest";
    user = "1000:${toString config.users.groups.media.gid}";
    environment = {
      TZ = config.time.timeZone;
      SLSKD_REMOTE_CONFIGURATION = "true";
      SLSKD_NO_HTTPS = "true";
    };
    volumes = [
      "${state}:/app"
      "${data}:${data}"
    ];
    extraOptions = [ "--network=host" ];
  };

  systemd.tmpfiles.rules = [ "Z ${state} - 1000 media -" ];
  systemd.services.podman-slskd.unitConfig.RequiresMountsFor = [ data ];

  networking.firewall.allowedTCPPorts = [ 50300 ];

  homeProxy.routes.slskd = 5030;
}

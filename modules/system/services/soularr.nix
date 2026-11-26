# Scope: NixOS system (Soularr container: fills Lidarr's wanted albums from Soulseek through slskd; no web UI, config.ini written by hand) | Used by: saturn
{ config, ... }:

let
  data = config.media.dataDir;
  state = "/var/lib/soularr";
in
{
  virtualisation.podman.enable = true;

  virtualisation.oci-containers.containers.soularr = {
    image = "docker.io/mrusse08/soularr:latest";
    user = "1000:${toString config.users.groups.media.gid}";
    environment = {
      TZ = config.time.timeZone;
      SCRIPT_INTERVAL = "300";
      WEBUI_ENABLED = "false";
    };
    volumes = [
      "${state}:/data"
      "${data}/slskd/downloads:/downloads"
    ];
    extraOptions = [ "--network=host" ];
  };

  systemd.tmpfiles.rules = [ "d ${state} 0750 1000 media -" ];
  systemd.services.podman-soularr.unitConfig = {
    RequiresMountsFor = [ data ];
    ConditionPathExists = "${state}/config.ini";
  };
}

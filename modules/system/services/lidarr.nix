# Scope: NixOS system (Lidarr at lidarr.<domain>: music, imported into the media tree) | Used by: saturn
{ config, ... }:

{
  services.lidarr = {
    enable = true;
    group = "media";
  };

  systemd.services.lidarr.unitConfig.RequiresMountsFor = [ config.media.dataDir ];

  homeProxy.routes.lidarr = 8686;
}

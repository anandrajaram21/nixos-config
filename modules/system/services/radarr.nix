# Scope: NixOS system (Radarr at radarr.<domain>: movies, imported into the media tree) | Used by: saturn
{ config, ... }:

{
  services.radarr = {
    enable = true;
    group = "media";
  };

  systemd.services.radarr.unitConfig.RequiresMountsFor = [ config.media.dataDir ];

  homeProxy.routes.radarr = 7878;
}

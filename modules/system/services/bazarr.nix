# Scope: NixOS system (Bazarr at bazarr.<domain>: subtitles for Sonarr and Radarr) | Used by: saturn
{ config, ... }:

{
  services.bazarr = {
    enable = true;
    group = "media";
  };

  systemd.services.bazarr.unitConfig.RequiresMountsFor = [ config.media.dataDir ];

  homeProxy.routes.bazarr = config.services.bazarr.settings.general.port;
}

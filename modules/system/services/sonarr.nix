# Scope: NixOS system (Sonarr at sonarr.<domain>: TV, imported into the media tree) | Used by: saturn
{ config, ... }:

{
  services.sonarr = {
    enable = true;
    group = "media";
  };

  systemd.services.sonarr.unitConfig.RequiresMountsFor = [ config.media.dataDir ];

  homeProxy.routes.sonarr = 8989;
}

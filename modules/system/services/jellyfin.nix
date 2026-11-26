# Scope: NixOS system (Jellyfin at jellyfin.<domain>, reading the library read-only) | Used by: saturn
{ config, ... }:

{
  services.jellyfin = {
    enable = true;
    group = "media";
  };

  systemd.services.jellyfin = {
    unitConfig.RequiresMountsFor = [ config.media.dataDir ];
    serviceConfig.ReadOnlyPaths = [ config.media.dataDir ];
  };

  homeProxy.routes.jellyfin = 8096;
}

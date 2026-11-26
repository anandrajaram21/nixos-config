# Scope: NixOS system (Jellyfin at jellyfin.<domain>, reading the library read-only; the host sets hardware transcoding) | Used by: saturn
{ config, ... }:

{
  services.jellyfin = {
    enable = true;
    group = "media";
  };

  systemd.services.jellyfin = {
    environment.JELLYFIN_PublishedServerUrl = "https://jellyfin.${config.homeProxy.domain}";
    unitConfig.RequiresMountsFor = [ config.media.dataDir ];
    serviceConfig.ReadOnlyPaths = [ config.media.dataDir ];
  };

  homeProxy.routes.jellyfin = 8096;
}

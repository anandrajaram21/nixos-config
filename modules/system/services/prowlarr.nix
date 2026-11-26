# Scope: NixOS system (Prowlarr at prowlarr.<domain>: indexers for Sonarr, Radarr and Lidarr) | Used by: saturn
{
  services.prowlarr.enable = true;

  homeProxy.routes.prowlarr = 9696;
}

# Scope: NixOS system (Lidarr at lidarr.<domain>: music, imported into the media tree) | Used by: saturn
{ config, ... }:

{
  services.lidarr = {
    enable = true;
    group = "media";
  };

  systemd.services.lidarr.unitConfig.RequiresMountsFor = [ config.media.dataDir ];

  # LIDARR__AUTH__APIKEY, so Soularr can share the key through sops.
  services.lidarr.environmentFiles = [ config.sops.templates."lidarr.env".path ];
  sops.templates."lidarr.env" = {
    content = "LIDARR__AUTH__APIKEY=${config.sops.placeholder.lidarr_api_key}\n";
  };
  # Restart on switch when the template or its encrypted secrets change.
  systemd.services.lidarr.restartTriggers = [
    config.sops.templates."lidarr.env".content
  ]
  ++ map (s: builtins.hashFile "sha256" config.sops.secrets.${s}.sopsFile) [ "lidarr_api_key" ];

  homeProxy.routes.lidarr = 8686;
}

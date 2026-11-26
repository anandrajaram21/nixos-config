# Scope: NixOS system (slskd at slskd.<domain>: Soulseek client sharing the music library; port 50300 open for peers) | Used by: saturn
{ config, ... }:

let
  data = config.media.dataDir;
in
{
  services.slskd = {
    enable = true;
    group = "media";
    openFirewall = true;
    environmentFile = config.sops.templates."slskd.env".path;
    settings = {
      directories = {
        downloads = "${data}/slskd/downloads";
        incomplete = "${data}/slskd/incomplete";
      };
      shares.directories = [ "${data}/media/music" ];
    };
  };

  # The host declares these sops secrets.
  sops.templates."slskd.env" = {
    content = ''
      SLSKD_SLSK_USERNAME=${config.sops.placeholder.soulseek_username}
      SLSKD_SLSK_PASSWORD=${config.sops.placeholder.soulseek_password}
      SLSKD_USERNAME=altf4
      SLSKD_PASSWORD=${config.sops.placeholder.slskd_web_password}
      SLSKD_API_KEY=${config.sops.placeholder.slskd_api_key}
    '';
  };
  # Restart on switch when the template or its encrypted secrets change.
  systemd.services.slskd.restartTriggers = [
    config.sops.templates."slskd.env".content
  ]
  ++ map (s: builtins.hashFile "sha256" config.sops.secrets.${s}.sopsFile) [
    "soulseek_username"
    "soulseek_password"
    "slskd_web_password"
    "slskd_api_key"
  ];

  systemd.services.slskd.unitConfig.RequiresMountsFor = [ data ];

  homeProxy.routes.slskd = config.services.slskd.settings.web.port;
}

# Scope: NixOS system (qBittorrent at qbittorrent.<domain>; BitTorrent port 6881 open for peers) | Used by: saturn
{ config, ... }:

{
  services.qbittorrent = {
    enable = true;
    group = "media";
    webuiPort = 8080;
    torrentingPort = 6881;
  };

  systemd.services.qbittorrent.unitConfig.RequiresMountsFor = [ config.media.dataDir ];

  networking.firewall = {
    allowedTCPPorts = [ 6881 ];
    allowedUDPPorts = [ 6881 ];
  };

  homeProxy.routes.qbittorrent = 8080;
}

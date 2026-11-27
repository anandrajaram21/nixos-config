# Scope: NixOS system (Beszel hub at beszel.<domain>: CPU, memory, disk, network, GPU and container history and alerts for every agent) | Used by: saturn
{ config, ... }:

{
  services.beszel.hub = {
    enable = true;
    port = 8090;
    environment.APP_URL = "https://beszel.${config.homeProxy.domain}";
  };

  homeProxy.routes.beszel = config.services.beszel.hub.port;
}

# Scope: NixOS system (Seerr at seerr.<domain>: movie and TV requests) | Used by: saturn
{ config, ... }:

{
  services.seerr.enable = true;

  homeProxy.routes.seerr = config.services.seerr.port;
}

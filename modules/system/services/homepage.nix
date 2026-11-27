# Scope: NixOS system (Homepage at homepage.<domain>: start page with a tile and up/down check per homeProxy route, plus CPU, memory and disk) | Used by: saturn
{ config, lib, ... }:

let
  domain = config.homeProxy.domain;
  port = 8082;
  tile = name: routePort: {
    "${lib.toUpper (lib.substring 0 1 name)}${lib.substring 1 (-1) name}" = {
      href = "https://${name}.${domain}";
      icon = "${name}.png";
      siteMonitor = "http://127.0.0.1:${toString routePort}";
    };
  };
in
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = port;
    allowedHosts = "homepage.${domain}";
    settings = {
      title = config.networking.hostName;
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
    };
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          cputemp = true;
          uptime = true;
        };
      }
    ];
    services = [
      {
        Services = lib.mapAttrsToList tile (removeAttrs config.homeProxy.routes [ "homepage" ]);
      }
    ];
  };

  homeProxy.routes.homepage = port;
}

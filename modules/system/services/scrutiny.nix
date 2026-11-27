# Scope: NixOS system (Scrutiny at scrutiny.<domain>: SMART disk health and failure warnings; reads SMART only) | Used by: saturn
{ config, ... }:

{
  services.scrutiny = {
    enable = true;
    settings.web.listen = {
      host = "127.0.0.1";
      port = 8072;
    };
    settings.web.influxdb.host = "127.0.0.1";
    collector.settings.host.id = config.networking.hostName;
  };

  services.influxdb2.settings.http-bind-address = "127.0.0.1:8086";

  homeProxy.routes.scrutiny = config.services.scrutiny.settings.web.listen.port;
}

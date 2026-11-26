# Scope: NixOS system (Caddy: HTTPS on <name>.<homeProxy.domain> for private services, Tailscale only, wildcard cert via Cloudflare DNS) | Used by: saturn
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeProxy;
  route = name: port: ''
    @${name} host ${name}.${cfg.domain}
    handle @${name} {
      reverse_proxy 127.0.0.1:${toString port}
    }
  '';
in
{
  options.homeProxy = {
    domain = lib.mkOption {
      type = lib.types.str;
      example = "home.example.com";
      description = "Services are served as <name>.<domain>; a wildcard DNS record points it at the Tailscale IP.";
    };
    routes = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      default = { };
      description = "Service name to local port. Service bricks add their own.";
    };
  };

  config = {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = "sha256-QSiwKqKvSxhksWBF4/MlBOpyXba5xOQ2sRwA0R7399E=";
      };
      environmentFile = config.sops.templates."caddy.env".path;
      virtualHosts."*.${cfg.domain}".extraConfig = ''
        tls {
          dns cloudflare {env.CF_API_TOKEN}
          resolvers 1.1.1.1
        }

        ${lib.concatStrings (lib.mapAttrsToList route cfg.routes)}
        handle {
          abort
        }
      '';
    };

    # The host declares sops.secrets.cloudflare_api_token (Zone > DNS > Edit, this zone only).
    sops.templates."caddy.env" = {
      content = "CF_API_TOKEN=${config.sops.placeholder.cloudflare_api_token}\n";
      owner = "caddy";
      restartUnits = [ "caddy.service" ];
    };

    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
    };
  };
}

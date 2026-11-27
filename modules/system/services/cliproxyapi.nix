# Scope: NixOS system (CLIProxyAPI at cliproxy.<domain>: OpenAI/Claude/Gemini/Codex/Grok API proxy for OAuth subscriptions; needs cliproxyapi_api_key and cliproxyapi_management_key secrets) | Used by: saturn
{ config, lib, ... }:

let
  port = 8317;
in
{
  services.cliproxyapi = {
    enable = true;
    settings = {
      config-version = lib.mkDefault 8;
      server = {
        host = lib.mkDefault "127.0.0.1";
        port = lib.mkDefault port;
        trusted-proxies = lib.mkDefault [
          "127.0.0.1"
          "::1"
        ];
      };
      management = {
        allow-remote = lib.mkDefault true;
        secret-key._secret = config.sops.secrets.cliproxyapi_management_key.path;
      };
      access.api-keys = [
        { _secret = config.sops.secrets.cliproxyapi_api_key.path; }
      ];
      routing = {
        strategy = lib.mkDefault "round-robin";
        session-affinity = lib.mkDefault true;
        session-affinity-ttl = lib.mkDefault "1h";
        retry = {
          request-retry = lib.mkDefault 3;
          max-retry-interval = lib.mkDefault 30;
        };
      };
    };
  };

  # Restart on switch when either encrypted secrets file changes.
  systemd.services.cliproxyapi.restartTriggers =
    map (s: builtins.hashFile "sha256" config.sops.secrets.${s}.sopsFile)
      [
        "cliproxyapi_api_key"
        "cliproxyapi_management_key"
      ];

  # Expose the CLI on PATH for headless OAuth logins (`sudo -u cliproxyapi cliproxyapi ...`).
  environment.systemPackages = [ config.services.cliproxyapi.package ];

  homeProxy.routes.cliproxy = config.services.cliproxyapi.settings.server.port;
}

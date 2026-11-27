# Scope: NixOS system (Beszel agent: reports this host to a Beszel hub; port 45876 open on tailscale0) | Used by: saturn
{ config, lib, ... }:

let
  cfg = config.services.beszel.agent;
in
{
  # Starts once the host sets services.beszel.agent.environment.KEY (the hub's public key, from its Add System dialog).
  services.beszel.agent.enable = cfg.environment ? KEY;

  # Container stats: the agent reads Podman through its Docker-compatible socket.
  virtualisation.podman.dockerSocket.enable = lib.mkDefault config.virtualisation.podman.enable;

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 45876 ];
}

# Scope: Cross-OS system, NixOS + nix-darwin (Grok Build CLI) | Used by: mercury, saturn
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.grok-build ];
  allowedUnfreePackages = [ "grok-build" ];
}

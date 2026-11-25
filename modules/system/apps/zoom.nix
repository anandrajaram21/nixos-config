# Scope: Cross-OS system, NixOS + nix-darwin (Zoom) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.zoom-us ];
  allowedUnfreePackages = [ "zoom" ];
}

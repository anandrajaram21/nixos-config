# Scope: Cross-OS system, NixOS + nix-darwin (Spotify) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.spotify ];
  allowedUnfreePackages = [ "spotify" ];
}

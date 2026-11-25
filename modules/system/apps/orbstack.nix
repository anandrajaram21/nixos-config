# Scope: nix-darwin system (OrbStack) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.orbstack ];
  allowedUnfreePackages = [ "orbstack" ];
}

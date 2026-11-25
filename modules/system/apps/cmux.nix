# Scope: nix-darwin system (cmux app) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.cmux ];
}

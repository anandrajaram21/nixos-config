# Scope: nix-darwin system (BetterDisplay) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.betterdisplay ];
  allowedUnfreePackages = [ "betterdisplay" ];
}

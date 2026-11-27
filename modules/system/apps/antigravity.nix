# Scope: Cross-OS system, NixOS + nix-darwin (Google Antigravity IDE) | Used by: mercury, saturn
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.antigravity-ide ];
  allowedUnfreePackages = [ "antigravity-ide" ];
}

# Scope: Cross-OS system, NixOS + nix-darwin (Slack) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.slack ];
  allowedUnfreePackages = [ "slack" ];
}

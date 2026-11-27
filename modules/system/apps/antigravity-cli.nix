# Scope: Cross-OS system, NixOS + nix-darwin (Antigravity CLI) | Used by: mercury, saturn
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.antigravity-cli ];
  allowedUnfreePackages = [ "antigravity-cli" ];
}

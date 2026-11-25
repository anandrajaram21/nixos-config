# Scope: Cross-OS system, NixOS + nix-darwin (Obsidian) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.obsidian ];
  allowedUnfreePackages = [ "obsidian" ];
}

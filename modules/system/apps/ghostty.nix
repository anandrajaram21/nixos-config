# Scope: nix-darwin system (Ghostty app; nixpkgs ghostty is Linux-only) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ghostty-bin ];
}

# Scope: Cross-OS system fonts (NixOS + nix-darwin) | Used by: mercury, saturn
{ pkgs, ... }:

{
  fonts.packages = [ pkgs.nerd-fonts.geist-mono ];
}

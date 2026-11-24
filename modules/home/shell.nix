# Scope: Home Manager (fish, starship, zoxide, direnv, neovim as editor) | Used by: mercury, saturn
{ pkgs, ... }:

{
  home.packages = [ pkgs.eza ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
    shellAliases.ls = "eza -lah";
  };
  programs.starship.enable = true;
  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  home.sessionVariables.VISUAL = "nvim";
}

{ pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
  ];

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    tmux
  ];
}

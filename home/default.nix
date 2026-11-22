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
    claude-code
    android-tools
    agent-browser
    beads
    bun
    pnpm
    uv
    php
    phpPackages.composer
  ];
}

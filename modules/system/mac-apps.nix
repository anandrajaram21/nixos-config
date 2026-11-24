# Scope: nix-darwin system (Mac GUI apps: nixpkgs first, Homebrew/App Store for the rest) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    betterdisplay
    cmux
    firefox-bin
    ghostty-bin
    obsidian
    orbstack
    slack
    spotify
    vscode
    zoom-us
  ];

  allowedUnfreePackages = [
    "betterdisplay"
    "firefox-bin"
    "firefox-bin-unwrapped"
    "obsidian"
    "orbstack"
    "slack"
    "spotify"
    "vscode"
    "zoom"
  ];

  homebrew = {
    brews = [
      "mas"
    ];
    casks = [
      "helium-browser"
      "local"
      "raycast"
      "tablepro"
      "tailscale-app"
      "vorssaint"
    ];
    masApps.Velja = 1607635845;
  };
}

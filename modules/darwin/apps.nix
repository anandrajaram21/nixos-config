{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    betterdisplay
    cmux
    firefox-bin
    ghostty-bin
    obsidian
    orbstack
    raycast
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
    "raycast"
    "slack"
    "spotify"
    "vscode"
    "zoom"
  ];
}

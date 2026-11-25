# Scope: nix-darwin system (Mac GUI apps: nixpkgs first, Homebrew/App Store for the rest) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    betterdisplay
    cmux
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
      "grok-bot"
      "helium-browser"
      "local"
      "raycast"
      "tablepro"
      "tailscale-app"
      "vorssaint"
    ];
    masApps.Velja = 1607635845;
  };

  # GUI apps (e.g. T3 Code's "Open in" menu) only search the default PATH for `code`.
  system.activationScripts.postActivation.text = ''
    mkdir -p /usr/local/bin
    ln -sfn /run/current-system/sw/bin/code /usr/local/bin/code
  '';
}

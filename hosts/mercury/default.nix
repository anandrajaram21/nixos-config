# Scope: Host entry point (nix-darwin) | Host: mercury
{
  imports = [
    ../../modules/system/shared.nix
    ../../modules/system/fonts.nix
    ../../modules/system/darwin-base.nix
    ../../modules/system/mac-defaults.nix
    ../../modules/system/apps/1password.nix
    ../../modules/system/apps/betterdisplay.nix
    ../../modules/system/apps/cmux.nix
    ../../modules/system/apps/ghostty.nix
    ../../modules/system/apps/grok-bot.nix
    ../../modules/system/apps/grok-build.nix
    ../../modules/system/apps/helium-browser.nix
    ../../modules/system/apps/hex.nix
    ../../modules/system/apps/local.nix
    ../../modules/system/apps/obsidian.nix
    ../../modules/system/apps/orbstack.nix
    ../../modules/system/apps/raycast.nix
    ../../modules/system/apps/slack.nix
    ../../modules/system/apps/spotify.nix
    ../../modules/system/apps/t3code-cask.nix
    ../../modules/system/apps/tablepro.nix
    ../../modules/system/apps/tailscale-app.nix
    ../../modules/system/apps/velja.nix
    ../../modules/system/apps/vorssaint.nix
    ../../modules/system/apps/vscode.nix
    ../../modules/system/apps/zoom.nix
  ];

  networking.hostName = "mercury";
  networking.computerName = "mercury";

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Install release; never change.
  system.stateVersion = 7;

  home-manager.users.altf4 = {
    imports = [
      ../../modules/home/shell.nix
      ../../modules/home/git.nix
      ../../modules/home/dev.nix
      ../../modules/home/claude-code.nix
      ../../modules/home/opencode.nix
      ../../modules/home/mac-user.nix
      ../../modules/home/mac-wallpaper.nix
      ../../modules/home/apps/1password.nix
      ../../modules/home/apps/cmux.nix
      ../../modules/home/apps/ghostty.nix
      ../../modules/home/apps/hex.nix
      ../../modules/home/apps/orbstack.nix
      ../../modules/home/apps/t3code.nix
      ../../modules/home/apps/vorssaint.nix
    ];

    # Install release; never change.
    home.stateVersion = "26.11";
  };
}

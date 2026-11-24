# Scope: Host entry point (nix-darwin) | Host: mercury
{
  imports = [
    ../../modules/system/shared.nix
    ../../modules/system/darwin-base.nix
    ../../modules/system/mac-apps.nix
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
      ../../modules/home/vorssaint.nix
    ];

    # Install release; never change.
    home.stateVersion = "26.11";
  };
}

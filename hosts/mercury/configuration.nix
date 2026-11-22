{
  imports = [
    ./homebrew.nix
    ../../modules/darwin
  ];

  networking.hostName = "mercury";
  networking.computerName = "mercury";

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Install release; never change.
  system.stateVersion = 7;
}

# Scope: nix-darwin system (any Mac) | Used by: mercury
{ pkgs, ... }:

{
  system.primaryUser = "altf4";
  users.users.altf4.home = "/Users/altf4";
  environment.shells = [ pkgs.fish ];

  nix.settings.trusted-users = [ "@admin" ];
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  sops.age.keyFile = "/Users/altf4/Library/Application Support/sops/age/keys.txt";

  homebrew = {
    enable = true;
    enableFishIntegration = true;
  };
}

{ pkgs, ... }:

{
  imports = [
    ./sops.nix
    ./unfree.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "Asia/Kolkata";

  programs.fish.enable = true;
  users.users.altf4.shell = pkgs.fish;
}

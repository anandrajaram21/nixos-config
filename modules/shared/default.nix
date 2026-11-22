{ pkgs, ... }:

{
  imports = [ ./sops.nix ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "Asia/Kolkata";

  services.tailscale.enable = true;

  programs.fish.enable = true;
  users.users.altf4.shell = pkgs.fish;
}

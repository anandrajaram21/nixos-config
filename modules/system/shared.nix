# Scope: Cross-OS system (NixOS + nix-darwin) | Used by: mercury, saturn
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.allowedUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };

  config = {
    nixpkgs.config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) config.allowedUnfreePackages;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    allowedUnfreePackages = [ "claude-code" ];

    sops.defaultSopsFile = ../../secrets/common.yaml;
    sops.secrets.github_ssh_key.owner = "altf4";

    time.timeZone = "Asia/Kolkata";

    programs.fish.enable = true;
    users.users.altf4.shell = pkgs.fish;
  };
}

{ config, lib, ... }:

{
  options.allowedUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };

  config.nixpkgs.config.allowUnfreePredicate =
    pkg: lib.elem (lib.getName pkg) config.allowedUnfreePackages;
}

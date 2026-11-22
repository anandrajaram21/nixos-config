{ config, lib, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg: lib.hasPrefix "nvidia" (lib.getName pkg);

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    # Pascal: no open modules, and 580 is the last series that supports it.
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    nvidiaPersistenced = true;

    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}

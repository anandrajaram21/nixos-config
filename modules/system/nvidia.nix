# Scope: NixOS system (NVIDIA dGPU with PRIME offload) | Used by: saturn
{ config, lib, ... }:

{
  allowedUnfreePackages = [
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
    "nvidia-kernel-modules"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  # open/package defaults suit Turing+; hosts set prime.{intel,nvidia}BusId and override for older GPUs.
  hardware.nvidia = {
    open = lib.mkDefault true;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
    prime.offload.enable = true;
  };
}

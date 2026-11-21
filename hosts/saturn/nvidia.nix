{ config, ... }:

{
  # The NVIDIA driver is proprietary, so nixpkgs refuses to build it unless unfree packages are allowed.
  nixpkgs.config.allowUnfree = true;

  # Despite the name, this is how NixOS selects the GPU driver even on a headless machine.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    # GTX 1060 Mobile is Pascal: the open kernel modules need Turing or newer,
    # and 580 is the last driver series that supports Pascal (the default `stable` is newer).
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    # No monitor attached, but keep the driver loaded so the GPU is ready for Plex/CUDA.
    nvidiaPersistenced = true;

    # Optimus board with the internal panel removed: the only display is HDMI, wired to the NVIDIA GPU.
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}

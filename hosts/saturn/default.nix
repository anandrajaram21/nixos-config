# Scope: Host entry point (NixOS) | Host: saturn
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/system/shared.nix
    ../../modules/system/fonts.nix
    ../../modules/system/nixos-base.nix
    ../../modules/system/server.nix
    ../../modules/system/nvidia.nix
    ../../modules/system/apps/t3code-server.nix
  ];

  # nouveau deadlocks when waking the GPU from runtime suspend.
  boot.kernelParams = lib.mkIf (!lib.elem "nvidia" config.services.xserver.videoDrivers) [
    "nouveau.runpm=0"
  ];

  hardware.enableRedistributableFirmware = true;

  # GTX 1060 is Pascal: no open modules, and 580 is the last series that supports it.
  hardware.nvidia = {
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    nvidiaPersistenced = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  networking.hostName = "saturn";

  # Irreplaceable data: keep read-only.
  boot.supportedFilesystems = [ "ntfs" ];
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/6CA2C4DCA2C4AC40";
    fsType = "ntfs3";
    options = [
      "ro"
      "nofail"
      "uid=1000"
      "gid=100"
      "umask=022"
    ];
  };

  users.users.altf4.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrmz9lXsHdKIIsF7C8pPhASp26icrNWPudfVBOk2GTC saturn"
  ];

  environment.systemPackages = [ pkgs.ntfs3g ];

  # Install release; never change.
  system.stateVersion = "26.05";

  home-manager.users.altf4 = {
    imports = [
      ../../modules/home/shell.nix
      ../../modules/home/git.nix
      ../../modules/home/dev.nix
      ../../modules/home/claude-code.nix
      ../../modules/home/opencode.nix
      ../../modules/home/apps/ghostty.nix
      ../../modules/home/apps/t3code.nix
    ];

    # Install release; never change.
    home.stateVersion = "26.05";
  };
}

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
    ./nvidia.nix
    ../../modules/nixos
  ];

  # nouveau deadlocks when waking the GPU from runtime suspend.
  boot.kernelParams = lib.mkIf (!lib.elem "nvidia" config.services.xserver.videoDrivers) [
    "nouveau.runpm=0"
  ];

  hardware.enableRedistributableFirmware = true;

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
}

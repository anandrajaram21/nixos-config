{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./nvidia.nix
    ../../modules/common.nix
  ];

  nix.settings.trusted-users = [ "@wheel" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # nouveau deadlocks when waking the GPU from runtime suspend.
  boot.kernelParams = [ "nouveau.runpm=0" ];

  hardware.enableRedistributableFirmware = true;
  zramSwap.enable = true;

  networking.hostName = "saturn";
  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  # Irreplaceable data: keep read-only.
  boot.supportedFilesystems = [ "ntfs" ];
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/6CA2C4DCA2C4AC40";
    fsType = "ntfs3";
    options = [ "ro" "nofail" "uid=1000" "gid=100" "umask=022" ];
  };

  users.users.altf4 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrmz9lXsHdKIIsF7C8pPhASp26icrNWPudfVBOk2GTC saturn"
    ];
  };
  security.sudo.wheelNeedsPassword = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    htop
    ntfs3g
  ];

  # Install release; never change.
  system.stateVersion = "26.05";
}

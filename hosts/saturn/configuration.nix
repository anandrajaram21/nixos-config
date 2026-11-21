{ pkgs, ... }:

{
  imports = [
    # Generated with `nixos-generate-config --no-filesystems`; disko provides the mounts.
    ./hardware-configuration.nix
    ./disko.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # The monitor's HDMI port is wired to the GTX 1060, so nouveau drives the console.
  # nouveau deadlocks when it wakes the GPU from runtime suspend (hung the installer twice),
  # so never let it suspend. nvidia.nix replaces nouveau entirely.
  boot.kernelParams = [ "nouveau.runpm=0" ];

  hardware.enableRedistributableFirmware = true;
  zramSwap.enable = true;

  networking.hostName = "saturn";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  # Existing NTFS data drive. Mounted by UUID so it never gets confused with the SSD,
  # and `nofail` so a missing/dirty disk doesn't stop the server from booting.
  # Starts read-only; switch "ro" to "rw" once you've confirmed it mounts cleanly.
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

  # Do not change after install; leave it at whatever nixos-generate-config wrote.
  system.stateVersion = "26.05";
}

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
    ../../modules/system/apps/antigravity-cli.nix
    ../../modules/system/apps/grok-build.nix
    ../../modules/system/apps/t3code-server.nix
    ../../modules/system/services/caddy.nix
    ../../modules/system/services/media.nix
    ../../modules/system/services/jellyfin.nix
    ../../modules/system/services/qbittorrent.nix
    ../../modules/system/services/prowlarr.nix
    ../../modules/system/services/flaresolverr.nix
    ../../modules/system/services/sonarr.nix
    ../../modules/system/services/radarr.nix
    ../../modules/system/services/lidarr.nix
    ../../modules/system/services/bazarr.nix
    ../../modules/system/services/seerr.nix
    ../../modules/system/services/slskd.nix
    ../../modules/system/services/soularr.nix
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

  # Irreplaceable data: mounted read-write only under root-only /srv/scoobydoo; /mnt/data is a read-only view, /data (media tree) the only writable one.
  boot.supportedFilesystems = [ "ntfs" ];
  systemd.tmpfiles.rules = [ "d /srv/scoobydoo 0700 root root -" ];
  fileSystems."/srv/scoobydoo/disk" = {
    device = "/dev/disk/by-uuid/6CA2C4DCA2C4AC40";
    fsType = "ntfs-3g";
    options = [
      "rw"
      "nofail"
      "uid=1000"
      "gid=${toString config.users.groups.media.gid}"
      "umask=002"
    ];
  };
  fileSystems."/mnt/data" = {
    device = "/srv/scoobydoo/disk";
    fsType = "none";
    options = [
      "bind"
      "ro"
      "nofail"
    ];
  };
  fileSystems.${config.media.dataDir} = {
    device = "/srv/scoobydoo/disk/data";
    fsType = "none";
    options = [
      "bind"
      "nofail"
    ];
  };

  homeProxy.domain = "home.anandrajaram.dev";

  sops.secrets.cloudflare_api_token.sopsFile = ../../secrets/saturn.yaml;

  # Jellyfin on the LAN too, for the TV (plain HTTP).
  networking.firewall.interfaces.enp7s0f1.allowedTCPPorts = [ 8096 ];

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

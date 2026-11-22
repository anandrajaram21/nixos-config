{ pkgs, ... }:

{
  imports = [ ../shared ];

  nix.settings.trusted-users = [ "@wheel" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap.enable = true;

  # Lets prebuilt Linux binaries (e.g. Node from fnm) find a dynamic loader.
  programs.nix-ld.enable = true;

  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.altf4 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  security.sudo.wheelNeedsPassword = true;

  services.tailscale.openFirewall = true;

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
  ];
}

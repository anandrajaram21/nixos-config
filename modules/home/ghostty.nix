# Scope: Home Manager (Ghostty config) | Used by: mercury, saturn
{ lib, ... }:

{
  programs.ghostty = {
    enable = true;
    # Config only; the app comes from mac-apps.nix (ghostty-bin) or a host/desktop brick.
    package = lib.mkDefault null;
    systemd.enable = lib.mkDefault false;
    settings = {
      font-family = "GeistMono NFM";
      font-size = 18;
    };
  };
}

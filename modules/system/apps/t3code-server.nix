# Scope: NixOS system (T3 Code server `t3`, official prebuilt nightly release with T3 Connect, as a boot service) | Used by: saturn
{ pkgs, lib, ... }:

let
  version = "0.1.14-nightly.20261128.5372";
  t3 = pkgs.stdenvNoCC.mkDerivation {
    pname = "t3code-server";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/t3-${version}-linux-x64.tar.gz";
      hash = "sha256-7UcTbVaWppMwONCmcW5gJpxQMLsrZPrid8E9jp0bMCI=";
    };
    # Node SEA binary: stripping or patchelf corrupts the embedded app, so it runs as-is via nix-ld.
    dontFixup = true;
    installPhase = ''
      mkdir -p $out/libexec $out/bin
      cp -r . $out/libexec/t3
      ln -s $out/libexec/t3/t3 $out/bin/t3
    '';
    meta.platforms = [ "x86_64-linux" ];
  };
  cloudflared = "${pkgs.cloudflared}/bin/cloudflared";
in
{
  programs.nix-ld.enable = true;
  environment.systemPackages = [ t3 ];
  environment.variables.T3CODE_CLOUDFLARED_PATH = cloudflared;

  systemd.services.t3code = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    environment = {
      HOME = "/home/altf4";
      T3CODE_CLOUDFLARED_PATH = cloudflared;
      PATH = lib.mkForce "/run/wrappers/bin:/home/altf4/.local/bin:/etc/profiles/per-user/altf4/bin:/run/current-system/sw/bin";
    };
    serviceConfig = {
      User = "altf4";
      WorkingDirectory = "/home/altf4";
      ExecStart = "${t3}/bin/t3 serve";
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 90;
    };
  };
}

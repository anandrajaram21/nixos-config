# Scope: NixOS system (T3 Code server `t3`, official prebuilt release with T3 Connect) | Used by: saturn
{ pkgs, ... }:

let
  version = "0.1.12";
  t3 = pkgs.stdenvNoCC.mkDerivation {
    pname = "t3code-server";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/t3-${version}-linux-x64.tar.gz";
      hash = "sha256-m6PbRuNVT7mXD9Xt6egjwvbW9nY/QDQL1MjvawlQHFQ=";
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
in
{
  programs.nix-ld.enable = true;
  environment.systemPackages = [ t3 ];
}

# Scope: NixOS system (T3 Code desktop app, official prebuilt AppImage with T3 Connect) | Used by: none yet (planned: venus)
{ pkgs, ... }:

let
  pname = "t3code";
  version = "0.1.12";
  src = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-x86_64.AppImage";
    hash = "sha256-ZrkVUVcd9tKbVctZApXt9BHP+WyVqP6z9Bw8pZXXIuI=";
  };
  contents = pkgs.appimageTools.extract { inherit pname version src; };
  t3code = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraInstallCommands = ''
      install -Dm444 ${contents}/t3code.desktop $out/share/applications/t3code.desktop
      substituteInPlace $out/share/applications/t3code.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=t3code'
      cp -r ${contents}/usr/share/icons $out/share/icons
    '';
    meta.platforms = [ "x86_64-linux" ];
  };
in
{
  environment.systemPackages = [ t3code ];
}

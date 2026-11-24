# Scope: Home Manager (macOS desktop wallpaper) | Used by: mercury
{
  config,
  pkgs,
  lib,
  ...
}:

let
  wallpaper = "Pictures/Wallpapers/bar.png";
  path = "${config.home.homeDirectory}/${wallpaper}";
in
{
  home.file.${wallpaper}.source = ../../assets/wallpapers/bar.png;

  home.activation.setWallpaper = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ "$(${pkgs.desktoppr}/bin/desktoppr | sort -u)" != "${path}" ]; then
      run ${pkgs.desktoppr}/bin/desktoppr "${path}" \
        || warnEcho "desktoppr: couldn't set the wallpaper"
    fi
  '';
}

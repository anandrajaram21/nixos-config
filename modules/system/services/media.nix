# Scope: NixOS system (media stack base: `media` group and the data tree path; the host mounts it) | Used by: saturn
{ lib, ... }:

{
  options.media.dataDir = lib.mkOption {
    type = lib.types.str;
    default = "/data";
    description = "Root of the media tree (torrents/, slskd/, media/). The host mounts it; media services only start once it is mounted.";
  };

  config.users.groups.media.gid = 2000;
}

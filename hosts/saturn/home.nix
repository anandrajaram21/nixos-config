{ osConfig, ... }:

let
  githubKey = osConfig.sops.secrets.github_ssh_key.path;
in
{
  imports = [ ../../home/common.nix ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      User = "git";
      IdentityFile = githubKey;
      IdentitiesOnly = true;
    };
  };

  programs.git.signing = {
    format = "ssh";
    key = githubKey;
    signByDefault = true;
  };

  # Install release; never change.
  home.stateVersion = "26.05";
}

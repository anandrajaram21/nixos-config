{ config, osConfig, ... }:

let
  githubKey = osConfig.sops.secrets.github_ssh_key.path;
  allowedSigners = ".ssh/allowed_signers";
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
  programs.git.settings.gpg.ssh.allowedSignersFile =
    "${config.home.homeDirectory}/${allowedSigners}";
  home.file.${allowedSigners}.text = ''
    anandrajaram21@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3HRYS2z4P96ld0XV+yUXIW9qXVbj1BU5zNKAvZz8Iw
  '';

  # Install release; never change.
  home.stateVersion = "26.05";
}

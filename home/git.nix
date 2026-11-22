{ config, osConfig, ... }:

let
  githubKey = osConfig.sops.secrets.github_ssh_key.path;
  allowedSigners = ".ssh/allowed_signers";
in
{
  programs.git = {
    enable = true;
    settings.user = {
      name = "Anand Rajaram";
      email = "anandrajaram21@gmail.com";
    };
    signing = {
      format = "ssh";
      key = githubKey;
      signByDefault = true;
    };
    settings.gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/${allowedSigners}";
  };

  programs.gh.enable = true;

  home.file.${allowedSigners}.text = ''
    ${config.programs.git.settings.user.email} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3HRYS2z4P96ld0XV+yUXIW9qXVbj1BU5zNKAvZz8Iw
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      User = "git";
      IdentityFile = githubKey;
      IdentitiesOnly = true;
    };
  };
}

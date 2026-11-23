# Scope: Home Manager (cross-platform: shell, git, CLI dev tools) | Used by: mercury, saturn
{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:

let
  githubKey = osConfig.sops.secrets.github_ssh_key.path;
  allowedSigners = ".ssh/allowed_signers";
in
{
  home.packages = with pkgs; [
    fnm
    eza
    ripgrep
    fd
    jq
    tmux
    claude-code
    android-tools
    agent-browser
    beads
    bun
    pnpm
    uv
    php
    phpPackages.composer
    opencode
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fnm env --use-on-cd --version-file-strategy=recursive --shell fish | source
    '';
    shellAliases = {
      ls = "eza -lah";
      oc = "opencode";
    };
  };
  programs.starship.enable = true;
  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  home.sessionVariables.VISUAL = "nvim";
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.activation.installNodeLts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.fnm}/bin/fnm list | grep -q default; then
      run ${pkgs.fnm}/bin/fnm install --lts \
        && run ${pkgs.fnm}/bin/fnm default lts-latest \
        || warnEcho "fnm: couldn't install Node LTS; run 'fnm install --lts' later"
    fi
  '';

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

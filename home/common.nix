{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    tmux
    fnm
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "Anand Rajaram";
      email = "anandrajaram21@gmail.com";
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fnm env --use-on-cd --version-file-strategy=recursive --shell fish | source
    '';
  };
  programs.starship.enable = true;
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
}

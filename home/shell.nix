{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    fnm
    eza
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fnm env --use-on-cd --version-file-strategy=recursive --shell fish | source
    '';
    shellAliases.ls = "eza -lah";
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
}

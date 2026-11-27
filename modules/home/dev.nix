# Scope: Home Manager (CLI dev tools and language runtimes: Node via fnm, Python via uv, Bun, PHP) | Used by: mercury, saturn
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    fnm
    ripgrep
    fd
    jq
    just
    tmux
    android-tools
    agent-browser
    bun
    pnpm
    uv
    php
    phpPackages.composer
  ];

  home.sessionVariables = {
    BUN_INSTALL = "$HOME/.bun";
    PNPM_HOME = lib.mkDefault "$HOME/.local/share/pnpm";
  };
  home.sessionPath = [
    "$HOME/.bun/bin"
    "$PNPM_HOME"
    "$HOME/.config/composer/vendor/bin"
    "$HOME/.local/bin"
  ];

  programs.fish.interactiveShellInit = ''
    fnm env --use-on-cd --version-file-strategy=recursive --shell fish | source
  '';

  home.activation.installNodeLts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.fnm}/bin/fnm list | grep -q default; then
      run ${pkgs.fnm}/bin/fnm install --lts \
        && run ${pkgs.fnm}/bin/fnm default lts-latest \
        || warnEcho "fnm: couldn't install Node LTS; run 'fnm install --lts' later"
    fi
  '';

  home.activation.installPython = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "$(${pkgs.uv}/bin/uv python list --only-installed --output-format json | ${pkgs.jq}/bin/jq '.[]?' 2>/dev/null)" ]; then
      run ${pkgs.uv}/bin/uv python install --default \
        || warnEcho "uv: couldn't install Python; run 'uv python install --default' later"
    fi
  '';
}

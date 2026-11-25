# Scope: Home Manager (macOS only) | Used by: mercury
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    sops
    age
  ];

  home.activation.lifeDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Life/Work" "$HOME/Life/Personal"
  '';

  home.sessionVariables = {
    BUN_INSTALL = "$HOME/.bun";
    PNPM_HOME = "$HOME/Library/pnpm";
  };
  home.sessionPath = [
    "$HOME/.bun/bin"
    "$HOME/Library/pnpm"
    "$HOME/.config/composer/vendor/bin"
    "$HOME/.local/bin"
  ];

  programs.fish = {
    interactiveShellInit = ''
      if test -d /opt/homebrew/opt/mysql-client/bin
        fish_add_path /opt/homebrew/opt/mysql-client/bin
      end
    '';
  };

  programs.ssh = {
    settings = {
      "saturn saturn.onca-minor.ts.net".HostName = "saturn";
    };
  };

  home.file.".hushlogin".text = "";
}

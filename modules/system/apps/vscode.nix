# Scope: nix-darwin system (VS Code, `code` on the default PATH) | Used by: mercury
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.vscode ];
  allowedUnfreePackages = [ "vscode" ];

  # GUI apps (e.g. T3 Code's "Open in" menu) only search the default PATH for `code`.
  system.activationScripts.postActivation.text = ''
    mkdir -p /usr/local/bin
    ln -sfn /run/current-system/sw/bin/code /usr/local/bin/code
  '';
}

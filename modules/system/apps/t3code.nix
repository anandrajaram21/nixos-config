# Scope: Cross-OS system, NixOS + nix-darwin (T3 Code app with T3 Connect) | Used by: mercury, saturn
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.t3code.override {
      enableCodex = false;
      enableGit = false;
      enableGitHub = false;
      # nixpkgs builds without T3's cloud config, which hides T3 Connect.
      # Public values copied from the official v0.1.8 release bundle.
      t3code-unwrapped = pkgs.t3code.unwrapped.overrideAttrs (old: {
        env = (old.env or { }) // {
          VITE_CLERK_PUBLISHABLE_KEY = "pk_live_Y2xlcmsudDMuY29kZXMk";
          VITE_CLERK_JWT_TEMPLATE = "t3-relay";
          VITE_T3CODE_RELAY_URL = "https://relay.t3.codes";
        };
      });
    })
  ];
}

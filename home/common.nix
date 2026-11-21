{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    tmux
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "Anand Rajaram";
      email = "anandrajaram21@gmail.com";
    };
  };

  programs.fish.enable = true;
  programs.starship.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}

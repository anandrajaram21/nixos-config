# Scope: Home Manager (OrbStack shell init and SSH config) | Used by: mercury
{
  programs.fish.interactiveShellInit = ''
    source ~/.orbstack/shell/init2.fish 2>/dev/null; or true
  '';
  programs.ssh.includes = [ "~/.orbstack/ssh/config" ];
}

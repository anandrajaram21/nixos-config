# Scope: Home Manager (SSH through the 1Password agent; GitHub uses the sops key from git.nix) | Used by: mercury
{
  programs.ssh.settings = {
    "github.com".IdentityAgent = "none";
    "*".IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
  };
}

# Scope: Home Manager (OpenCode CLI and its settings) | Used by: mercury, saturn
{
  programs.fish.shellAliases.oc = "opencode";

  programs.opencode = {
    enable = true;
    mutableSettings = true;
    settings.permissions = [
      {
        action = "*";
        resource = "*";
        effect = "allow";
      }
    ];
  };
}

# Scope: Home Manager (Claude Code CLI and its settings) | Used by: mercury, saturn
{
  programs.claude-code = {
    enable = true;
    mutableSettings = true;
    settings = {
      permissions.defaultMode = "bypassPermissions";
      skipDangerousModePermissionPrompt = true;
      autoMemoryEnabled = false;
      attribution = {
        commit = "";
        pr = "";
      };
    };
  };
}

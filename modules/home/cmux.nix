# Scope: Home Manager (cmux config) | Used by: mercury
{
  xdg.configFile."cmux/cmux.json".text = builtins.toJSON {
    "$schema" = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";
    schemaVersion = 1;
    app = {
      appearance = "system";
      confirmQuit = "never";
      workspaceInheritWorkingDirectory = false;
    };
    browser = {
      openTerminalLinksInCmuxBrowser = false;
      interceptTerminalOpenCommandInCmuxBrowser = false;
    };
    sidebarAppearance = {
      matchTerminalBackground = true;
      tintColor = "#000000";
      tintOpacity = 0.18;
    };
    computerUse.enabled = false;
  };
}

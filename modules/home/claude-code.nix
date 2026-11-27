# Scope: Home Manager (Claude Code CLI and its settings; routes through cliproxy when cliproxy.url is set) | Used by: mercury, saturn
{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  cliproxyUrl = osConfig.cliproxy.url;
  keyFile = osConfig.sops.secrets.cliproxyapi_api_key.path;

  authHelper = pkgs.writeShellScript "claude-cliproxy-auth" ''
    exec ${lib.getExe' pkgs.coreutils "tr"} -d '\r\n' < ${lib.escapeShellArg keyFile}
  '';
in
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
    }
    // lib.optionalAttrs (cliproxyUrl != null) {
      apiKeyHelper = toString authHelper;
      env.ANTHROPIC_BASE_URL = cliproxyUrl;
    };
  };
}

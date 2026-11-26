# Scope: Home Manager (T3 Code settings, merged into its files on every switch; app in system/apps/t3code-cask.nix or t3code-server.nix) | Used by: mercury, saturn
{ pkgs, lib, ... }:

let
  serverSettings = {
    idleCompaction = "onReturn";
    branchNamingMode = "semantic";
    favorites = [
      {
        provider = "claudeAgent";
        model = "claude-opus-5-5";
      }
      {
        provider = "claudeAgent";
        model = "claude-sonnet-5-5";
      }
    ];
    storageCleanup = {
      worktreeAfterDays = 2;
      worktreeSettledAfterDays = 2;
      worktreeOnMerge = true;
      worktreeOnDelete = true;
      worktreeUnchanged = true;
    };
    providerInstances = {
      opencode = {
        driver = "opencode";
        enabled = true;
      };
      codex = {
        driver = "codex";
        enabled = false;
      };
    };
  };

  clientSettings = {
    notificationMode = "off";
    inAppNotificationsEnabled = false;
    diffColorScheme = "red-green";
    chatWidth = "comfortable";
    effortDisplay = "label";
    loadBalancingEnabled = false;
    loadBalancingWeights = { };
    appearanceContrast = 200;
    panelAnimationDurationMs = 0;
    browserDefaultViewport = {
      _tag = "fill";
    };
    browserDefaultZoomFactor = 1;
    browserDefaultAppearance = "system";
    browserRecordingFrameRate = 30;
    browserRecordingShowKeyPresses = false;
    browserRecordingShowMousePresses = false;
    browserLinkTarget = "system";
    browserSearchEngine = "duckduckgo";
    browserCustomSearchUrl = "";
    browserAutoShowFloatingPreview = true;
    browserProfiles = [ ];
    browserDefaultProfileId = "default";
    confirmQuit = "hold";
    confirmThreadArchive = false;
    confirmThreadDelete = true;
    confirmThreadUnpin = false;
    diffFilesCollapsed = true;
    diffIgnoreWhitespace = true;
    diffLayout = "stacked";
    environmentIdentificationMode = "artwork";
    glassOpacity = 80;
    fontSizeInterface = 16;
    fontSizePrompt = 14;
    fontSizeCode = 18;
    fontSizeTerminal = 18;
    fontFamilyCode = "GeistMono NFM";
    fontFamilyComposer = "";
    fontFamilySans = "";
    fontFamilyTerminal = "GeistMono NFM";
    fontSmoothing = true;
    persistComposerContextStrip = false;
    favorites = [ ];
    providerModelPreferences = { };
    pullRequestMergeMethodOverrides = { };
    pullRequestLinksOpenInApp = true;
    composerRichTextEnabled = true;
    sendShortcut = "enter";
    followUpBehavior = "steer";
    proactivePanelsEnabled = false;
    showSkillsInSlashMenu = true;
    boringSidebarEnabled = false;
    boringSidebarMultilineRows = false;
    toolCallVisibility = "showAll";
    threadDetailsUsageEnabled = false;
    threadDetailsItems = {
      usage = true;
      context = true;
    };
    sidebarWorkingShelfEnabled = true;
    sidebarProjectGroupingMode = "repository";
    sidebarProjectGroupingOverrides = { };
    sidebarProjectSortOrder = "updated_at";
    sidebarThreadSortOrder = "updated_at";
    timestampFormat = "locale";
    voiceMicrophone = "";
    voiceShortcutMode = "auto";
    speechLanguage = "auto";
    speechTranslateToEnglish = false;
    speechCustomWords = [ ];
    speechSilenceFiltering = true;
    speechRemoveFillerWords = true;
    speechPostProcessingPrompt = {
      mode = "default";
      customInstructions = "";
    };
    speechCorrectionWord = "";
    snapShotEnabled = false;
    snapShotIncludeAccessibility = true;
    snapShotShortcut = {
      kind = "both-shift-keys";
    };
    snapShotPlaySound = true;
    snapShotSound = "soft-pop";
    snapShotFlash = true;
    snapShotAnimations = true;
    wordWrap = true;
    mathRenderingEnabled = false;
  };

  json = pkgs.formats.json { };
  merge = file: settings: ''
    f="$HOME/.t3/userdata/${file}"
    if [[ ! -v DRY_RUN ]]; then
      mkdir -p "$HOME/.t3/userdata"
      if [[ -s "$f" ]]; then
        tmp="$(mktemp)"
        ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$f" ${json.generate file settings} > "$tmp"
        mv "$tmp" "$f"
      else
        install -m 644 ${json.generate file settings} "$f"
      fi
    fi
  '';
in
{
  home.activation.t3codeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${merge "settings.json" serverSettings}
    ${merge "client-settings.json" clientSettings}
  '';
}

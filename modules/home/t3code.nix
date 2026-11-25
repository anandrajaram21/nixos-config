# Scope: Home Manager (T3 Code app and settings, merged into its files on every switch) | Used by: mercury, saturn
{ pkgs, lib, ... }:

let
  serverSettings = {
    idleCompaction = "onReturn";
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
  home.packages = [
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

  home.activation.t3codeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${merge "settings.json" serverSettings}
    ${merge "client-settings.json" clientSettings}
  '';
}

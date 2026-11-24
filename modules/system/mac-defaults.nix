# Scope: nix-darwin system (macOS preferences for the primary user) | Used by: mercury
{ config, ... }:

let
  asUser = "launchctl asuser \"$(id -u -- ${config.system.primaryUser})\" sudo --user=${config.system.primaryUser} --";
in
{
  system.defaults = {
    dock = {
      persistent-apps = [ ];
      persistent-others = [ ];
      show-recents = false;
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      "com.apple.mouse.tapBehavior" = 1;
      NSStatusItemSpacing = 6;
      NSStatusItemSelectionPadding = 4;
    };

    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 14400;
    };

    CustomUserPreferences."com.apple.dock".recent-apps = [ ];
  };

  # Tap to click also needs the per-host key; activateSettings applies trackpad changes without a logout.
  system.activationScripts.postActivation.text = ''
    ${asUser} defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
    ${asUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}

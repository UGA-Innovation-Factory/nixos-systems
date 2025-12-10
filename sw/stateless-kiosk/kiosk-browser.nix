{ config, lib, pkgs, ... }:

let
  kioskPolicies = {
    DisableAppUpdate = true;
    DisableFirefoxStudies = true;
    DisableTelemetry = true;
    DisablePocket = true;
    DisableSetDesktopBackground = true;
    DisableFeedbackCommands = true;
    DontCheckDefaultBrowser = true;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    NoDefaultBookmarks = true;
    DisableProfileImport = true;

    Permissions = {
      Camera        = { Allow = ["homeassistant.lan"]; };
      Microphone    = { Allow = ["homeassistant.lan"]; };
      Location      = { Allow = ["homeassistant.lan"]; };
      Notifications = { Allow = ["homeassistant.lan"]; };
      Clipboard     = { Allow = ["homeassistant.lan"]; };
      Fullscreen    = { Allow = ["homeassistant.lan"]; };
    };
  };

  extraPrefs = pkgs.writeText "kiosk-prefs.js" ''
    pref("browser.shell.checkDefaultBrowser", false);
    pref("browser.startup.homepage_override.mstone", "ignore");
    pref("startup.homepage_welcome_url", "");
    pref("startup.homepage_welcome_url.additional", "");
    pref("browser.sessionstore.resume_from_crash", false);
    pref("browser.sessionstore.max_resumed_crashes", 0);
    pref("network.captive-portal-service.enabled", false);
    pref("network.connectivity-service.enabled", false);
    pref("browser.messaging-system.whatsNewPanel.enabled", false);
    pref("browser.aboutwelcome.enabled", false);
    pref("privacy.popups.showBrowserMessage", false);
  '';

  firefoxWrapped = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    extraPolicies = kioskPolicies;
    extraPrefsFiles = [ extraPrefs ];
  };

  firefoxKiosk = pkgs.writeShellScriptBin "firefoxkiosk" ''
    #!/usr/bin/env bash
    set -eu

    BASE="http://homeassistant.lan:8123"

    get_primary_mac() {
      for dev in /sys/class/net/*; do
        iface="$(basename "$dev")"
        [ "$iface" = "lo" ] && continue
        if [ -f "$dev/type" ] && [ "$(cat "$dev/type")" = "1" ]; then
          cat "$dev/address"
          return 0
        fi
      done
      return 1
    }

    MAC="$(get_primary_mac 2>/dev/null || echo "")"
    MAC="$(echo "$MAC" | tr '[:upper:]' '[:lower:]')"

    case "$MAC" in
      "00:e0:4c:46:0b:32") STATION="1" ;;
      "00:e0:4c:46:07:26") STATION="2" ;; 
      "00:e0:4c:46:05:94") STATION="3" ;;
      "00:e0:4c:46:07:11") STATION="4" ;;
      "00:e0:4c:46:08:02") STATION="5" ;;
      "00:e0:4c:46:08:5c") STATION="6" ;;
      *) ;;
    esac

    DEFAULT_PATH="lovelace/0"
    PATH_PART="$DEFAULT_PATH"
    BROWSER_ID=""  # browser_mod identifier

    if [ -n "$STATION" ]; then
      PATH_PART="assembly-line/$STATION"
      BROWSER_ID="Station%20$STATION"
    fi

    URL="$BASE/$PATH_PART"

    # Add BrowserID query param if we have one
    if [ -n "$BROWSER_ID" ]; then
      if [[ "$URL" == *"?"* ]]; then
	URL="$URL&BrowserID=$BROWSER_ID"
      else
	URL="$URL?BrowserID=$BROWSER_ID"
      fi
    fi

    sleep 2

    exec ${firefoxWrapped}/bin/firefox --kiosk "$URL"
  '';
in
{
  environment.systemPackages = [ firefoxKiosk ];

  services.xserver.enable = false;
  services.seatd.enable = true;

  services.cage = {
    enable = true;
    user = "engr-ugaif";
    program = "${firefoxKiosk}/bin/firefoxkiosk";
  };

  systemd.services.cage = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}

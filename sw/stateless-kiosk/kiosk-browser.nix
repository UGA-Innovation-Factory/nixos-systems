
# This module configures Chromium for kiosk mode under Sway.
# It includes a startup script that determines the kiosk URL based on the machine's MAC address.
{ config, lib, pkgs, ... }:

let
  macCaseBuilder = (import ./mac-hostmap.nix { inherit lib; }).macCaseBuilder;
  macCases = macCaseBuilder {
    varName = "STATION";
  };
  chromiumKiosk = pkgs.writeShellScriptBin "chromiumkiosk" ''
    #!/usr/bin/env bash
    set -eu

    BASE="http://homeassistant.lan:8123"

    # Helper to find the primary MAC address
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

    # Map MAC addresses to specific station IDs
    case "$MAC" in
      ${macCases}
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

    exec ${pkgs.chromium}/bin/chromium --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble "$URL"
  '';
in
{
  environment.systemPackages = [
    pkgs.chromium
    chromiumKiosk
  ];

  systemd.user.services.chromium-kiosk = {
    description = "Chromium Kiosk";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${chromiumKiosk}/bin/chromiumkiosk";
      Restart = "on-failure";
      Type = "simple";
    };
  };
}

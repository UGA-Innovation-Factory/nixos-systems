{ config, lib, pkgs, ... }:
let
  macCaseBuilder = (import ./mac-hostmap.nix { inherit lib; }).macCaseBuilder;
  shellCases = macCaseBuilder {
    varName = "NEW_HOST";
    prefix = "nix-station";
  };
in
{
  services.xserver.enable = false;
  services.seatd.enable = true;
  services.openssh.enable = true;
  services.dbus.enable = true;
  security.polkit.enable = true;

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "engr-ugaif";
    };

    sddm = {
      enable = true;
      wayland.enable = true;
    };

    defaultSession = "sway";
  };

  systemd.services.dynamic-hostname = {
    description = "Set hostname based on MAC address";
    wantedBy = [ "sysinit.target" ];
    before = [ "network-pre.target" ];
    wants = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "dynamic-hostname" ''
        set -euo pipefail

        # Pick first non-loopback interface with a MAC
        IFACE="$(ls /sys/class/net | grep -v '^lo$' | head -n1)"
        MAC="$(cat /sys/class/net/$IFACE/address | tr '[:upper:]' '[:lower:]')"

        case "$MAC" in
          ${shellCases}
          *) NEW_HOST="nix-station-anon" ;;
        esac

        ${pkgs.nettools}/bin/hostname "$NEW_HOST"
      '';
    };
  };

  # Sway background as soon as the compositor is running
  systemd.user.services.swaybg-on-sway = {
    description = "Set background once Sway compositor is running";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.swaybg}/bin/swaybg \
          --image ${../../assets/if_logo.png} \
          --mode center \
          --color '#ffffff'
      '';
    };
  };
  
  # System-level ping service: wait for the kiosk URL to become reachable
  systemd.services.kiosk-ping = {
    description = "Wait for homeassistant.lan:8123 to be reachable";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        #!/usr/bin/env bash
        set -euo pipefail

        URL="http://homeassistant.lan:8123"

        timeout=30
        elapsed=0
        while ! ${pkgs.curl}/bin/curl -sf --max-time 2 "$URL" >/dev/null; do
          sleep 1
          elapsed=$((elapsed+1))
          if [ "$elapsed" -ge "$timeout" ]; then
            echo "ERROR: $URL did not resolve after $timeout seconds" >&2
            exit 1
          fi
        done
      '';
    };
  };

  systemd.targets.kiosk-ping = {
    description = "Kiosk network/ping readiness target";
    wants = [ "kiosk-ping.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.targets."plymouth-wait-for-ping" = {
    description = "Plymouth wait for kiosk-ping target";
    wantedBy = [ "multi-user.target" ];
    before = [ "plymouth-quit.service" ];
    after = [ "kiosk-ping.target" ];
  };
}

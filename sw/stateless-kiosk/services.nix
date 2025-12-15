{
  config,
  lib,
  pkgs,
  ...
}:
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
}

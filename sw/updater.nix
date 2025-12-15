{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.ugaif.sw.remoteBuild = lib.mkOption {
    type = types.submodule {
      options = {
        hosts = mkOption {
          type = types.listOf types.str;
          default = [ "engr-ugaif@192.168.11.133 x86_64-linux" ];
          description = "List of remote build hosts for system rebuilding.";
        };

        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable remote build for 'update-system' command.";
        };
      };
    };
    default = { };
    description = "Remote build configuration";
  };

  config = {
    ugaif.sw.remoteBuild.enable = lib.mkDefault (config.ugaif.sw.type == "tablet-kiosk");

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "update-system" ''
        set -euo pipefail

        UNIT="update-system.service"

        # Start following logs in the background
        journalctl -fu "$UNIT" -n 0 --output=cat &
        JPID=$!

        # Start the service and wait for it to finish
        if systemctl start --wait --no-ask-password "$UNIT"; then
          STATUS=$?
        else
          STATUS=$?
        fi

        sleep 2

        # Kill the log follower
        kill "$JPID" 2>/dev/null || true

        exit "$STATUS"
      '')
    ];

    systemd.services.update-system = {
      enable = true;
      description = "System daemon to one-shot run the Nix updater from fleet flake as root";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = 
          let
            hosts = config.ugaif.sw.remoteBuild.hosts;
            builders = lib.strings.concatMapStringsSep ";" (x: x) hosts;
            rebuildCmd = "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --refresh";
            source = "--flake github:UGA-Innovation-Factory/nixos-systems";
            remoteBuildFlags = if config.ugaif.sw.remoteBuild.enable
              then
                ''--builders "${builders}"''
              else "";
          in
            "${rebuildCmd} ${remoteBuildFlags} --print-build-logs ${source}#${config.networking.hostName}";
        User = "root";
        Group = "root";
        TimeoutStartSec = "0";
      };
    };

    security.polkit = {
      debug = true;
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "update-system.service" &&
              action.lookup("verb") == "start" &&
              subject.isInGroup("users")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
  };
}

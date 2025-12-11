{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.modules.sw.remoteBuild = lib.mkOption {
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
    modules.sw.remoteBuild.enable = lib.mkDefault (config.modules.sw.type == "tablet-kiosk");

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "update-system" ''
        set -euo pipefail

        UNIT="update-system.service"

        # Start following logs in the background
        journalctl -fu "$UNIT" --output=cat &
        JPID=$!

        # Start the service and wait for it to finish
        if systemctl start --wait "$UNIT"; then
          STATUS=$?
        else
          STATUS=$?
        fi

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
            hosts = config.modules.sw.remoteBuild.hosts;
            builders = lib.strings.concatMapStringsSep ";" (x: x) hosts;
            rebuildCmd = "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --refresh";
            source = "--flake github:UGA-Innovation-Factory/nixos-systems";
            remoteBuildFlags = if config.modules.sw.remoteBuild.enable
              then
                ''--builders "${builders}"''
              else "";
          in
            "${rebuildCmd} ${remoteBuildFlags} ${source}#${config.networking.hostName}";
        User = "root";
        Group = "root";
      };
    };

    security.polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "update-system.service" &&
              action.lookup("verb") == "start" &&
              subject.isInGroup("users")) {
            return polkit.Result.YES;
          }
        };
      '';
    };
  };
}

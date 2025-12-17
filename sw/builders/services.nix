{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.ugaif.sw;
  builderCfg = cfg.builders;
in
mkIf builderCfg.githubRunner.enable {
  services.github-runners.${builderCfg.githubRunner.name} = {
    enable = true;
    url = builderCfg.githubRunner.url;
    tokenFile = builderCfg.githubRunner.tokenFile;
    extraLabels = builderCfg.githubRunner.extraLabels;
    user = builderCfg.githubRunner.user;
    workDir = builderCfg.githubRunner.workDir;
    replace = true;
  };

  # Configure the systemd service for better handling of cleanup and restarts
  systemd.services."github-runner-${builderCfg.githubRunner.name}" = {
    unitConfig = {
      # Only start the service if token file exists
      # This allows graceful deployment before the token is manually installed
      ConditionPathExists = builderCfg.githubRunner.tokenFile;
    };
    serviceConfig = {
      # Give the service more time to stop cleanly
      TimeoutStopSec = 60;
      # Ensure all processes are killed on stop
      KillMode = "mixed";
      KillSignal = "SIGTERM";
      # Restart on failure, but not immediately
      RestartSec = 10;
    };
    # Add a pre-start script to forcefully clean up if directory is busy
    preStart = mkBefore ''
      # If the directory exists and appears stuck, try to force cleanup
      if [ -d "${builderCfg.githubRunner.workDir}/${builderCfg.githubRunner.name}" ]; then
        echo "Attempting to clean up existing runner directory..."
        # Kill any lingering processes that might have the directory open
        ${pkgs.procps}/bin/pkill -u ${builderCfg.githubRunner.user} -f "Runner.Listener" || true
        sleep 2
        # Try to remove the directory contents
        find "${builderCfg.githubRunner.workDir}/${builderCfg.githubRunner.name}" -mindepth 1 -delete 2>/dev/null || true
      fi
    '';
  };

  # Ensure the work directory exists with proper ownership
  systemd.tmpfiles.rules = [
    "d ${builderCfg.githubRunner.workDir} 0755 ${builderCfg.githubRunner.user} ${builderCfg.githubRunner.user} -"
  ];
}

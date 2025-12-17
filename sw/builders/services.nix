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
      # Restart on failure, but not immediately
      RestartSec = 10;
    };
    # Override the ExecStartPre to not fail if cleanup has issues
    # The '-' prefix means the command failure won't cause the service to fail
    path = mkForce (
      let
        originalPath = config.systemd.services."github-runner-${builderCfg.githubRunner.name}".path;
      in
      originalPath
    );
  };

  # Override the unconfigure script to be failure-tolerant
  systemd.services."github-runner-${builderCfg.githubRunner.name}".serviceConfig.ExecStartPre = mkForce [
    (
      let
        unconfigureScript = pkgs.writeShellScript "github-runner-${builderCfg.githubRunner.name}-unconfigure.sh" ''
          set +e  # Don't exit on error
          
          runnerDir="${builderCfg.githubRunner.workDir}/${builderCfg.githubRunner.name}"
          
          # Try to remove the runner registration if it exists
          if [ -e "$runnerDir" ]; then
            echo "Cleaning up runner directory: $runnerDir"
            
            # Try to remove contents, but don't fail if busy
            find "$runnerDir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
            
            # If directory still has content but we couldn't delete it, just warn
            if [ "$(ls -A $runnerDir 2>/dev/null)" ]; then
              echo "Warning: Could not fully clean $runnerDir (may be in use)"
              echo "This is normal on first deployment or if runner is already running"
            fi
          fi
          
          exit 0  # Always succeed
        '';
      in
      "-${unconfigureScript} ${builderCfg.githubRunner.workDir}/${builderCfg.githubRunner.name} ${builderCfg.githubRunner.workDir} /var/log/github-runner/${builderCfg.githubRunner.name}"
    )
  ];

  # Ensure the work directory exists with proper ownership
  systemd.tmpfiles.rules = [
    "d ${builderCfg.githubRunner.workDir} 0755 ${builderCfg.githubRunner.user} ${builderCfg.githubRunner.user} -"
  ];
}

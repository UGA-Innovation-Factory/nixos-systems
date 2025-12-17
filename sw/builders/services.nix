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
    replace = builderCfg.githubRunner.replace;
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
      
      # Disable all namespace isolation features that don't work in LXC containers
      PrivateMounts = mkForce false;
      MountAPIVFS = mkForce false;
      BindPaths = mkForce [ ];
      BindReadOnlyPaths = mkForce [ ];
      PrivateTmp = mkForce false;
      PrivateDevices = mkForce false;
      ProtectSystem = mkForce false;
      ProtectHome = mkForce false;
      ReadOnlyPaths = mkForce [ ];
      InaccessiblePaths = mkForce [ ];
      PrivateUsers = mkForce false;
      ProtectKernelTunables = mkForce false;
      ProtectKernelModules = mkForce false;
      ProtectControlGroups = mkForce false;
      
      # Don't override ExecStartPre - let the default module handle configuration
      # Just make the cleanup more tolerant by wrapping the original script
      ExecStartPre = mkForce (
        let
          # Get the runner package and scripts
          runnerPkg = pkgs.github-runner;
          
          # Create wrapper scripts that are failure-tolerant
          unconfigureWrapper = pkgs.writeShellScript "github-runner-unconfigure-wrapper.sh" ''
            set +e  # Don't fail on errors
            
            runnerDir="$1"
            stateDir="$2"
            logDir="$3"
            
            # If directory is busy, just skip cleanup with a warning
            if [ -d "$runnerDir" ]; then
              echo "Attempting cleanup of $runnerDir..."
              find "$runnerDir" -mindepth 1 -maxdepth 1 -delete 2>/dev/null || {
                echo "Warning: Cleanup had issues (directory may be in use), continuing anyway..."
              }
            fi
            
            exit 0
          '';
          
          configureScript = pkgs.writeShellScript "github-runner-configure.sh" ''
            set -e
            
            runnerDir="${builderCfg.githubRunner.workDir}/${builderCfg.githubRunner.name}"
            token=$(cat "${builderCfg.githubRunner.tokenFile}")
            
            cd "$runnerDir"
            
            # Configure the runner, optionally replacing existing registration
            if [ ! -f ".runner" ] || [ "${if builderCfg.githubRunner.replace then "true" else "false"}" = "true" ]; then
              echo "Configuring GitHub Actions runner..."
              ${runnerPkg}/bin/Runner.Listener configure \
                --unattended \
                --url "${builderCfg.githubRunner.url}" \
                --token "$token" \
                --name "$(hostname)" \
                --labels "${lib.concatStringsSep "," builderCfg.githubRunner.extraLabels}" \
                --work "_work" \
                ${if builderCfg.githubRunner.replace then "--replace" else ""}
            else
              echo "Runner already configured, skipping configuration."
            fi
          '';
        in
        [
          "-${unconfigureWrapper} ${builderCfg.githubRunner.workDir}/${builderCfg.githubRunner.name} ${builderCfg.githubRunner.workDir} /var/log/github-runner/${builderCfg.githubRunner.name}"
          "${configureScript}"
        ]
      );
    };
  };

  # Ensure the work directory exists with proper ownership
  systemd.tmpfiles.rules = [
    "d ${builderCfg.githubRunner.workDir} 0755 ${builderCfg.githubRunner.user} ${builderCfg.githubRunner.user} -"
  ];
}

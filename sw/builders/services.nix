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

  # Add systemd condition to only start the service if token file exists
  # This allows graceful deployment before the token is manually installed
  systemd.services."github-runner-${builderCfg.githubRunner.name}".unitConfig = {
    ConditionPathExists = builderCfg.githubRunner.tokenFile;
  };

  # Ensure the work directory exists with proper ownership before service starts
  systemd.tmpfiles.rules = [
    "d ${builderCfg.githubRunner.workDir} 0755 ${builderCfg.githubRunner.user} ${builderCfg.githubRunner.user} -"
    "d ${builderCfg.githubRunner.workDir}/${builderCfg.githubRunner.name} 0755 ${builderCfg.githubRunner.user} ${builderCfg.githubRunner.user} -"
  ];
}

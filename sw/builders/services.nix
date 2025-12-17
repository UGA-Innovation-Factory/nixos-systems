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
}

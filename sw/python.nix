{ config, lib, pkgs, ... }:

# ============================================================================
# Python Environment
# ============================================================================
# This module provides Python development tools. It installs 'pixi' and 'uv'
# for project-based dependency management, rather than installing global
# Python packages which can lead to conflicts.

with lib;

let
  cfg = config.modules.sw.python;
in {
  options.modules.sw.python = {
    enable = mkEnableOption "Python development tools (pixi, uv)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.buildFHSEnv {
        name = "pixi";
        runScript = "pixi";
        targetPkgs = pkgs: with pkgs; [ pixi ];
      })
      pkgs.uv
    ];
  };
}

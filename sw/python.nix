{ config, lib, pkgs, ... }:

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

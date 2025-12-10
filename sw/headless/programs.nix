{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.modules.sw;
  basePackages = with pkgs; [
    tmux
    man
  ];
in
{
  environment.systemPackages = subtractLists cfg.excludePackages (basePackages ++ cfg.extraPackages);

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}

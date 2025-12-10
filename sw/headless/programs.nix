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
    uv
    perl
    openssh
    ncurses
    tmux
    htop
    binutils
    man
    git
    oh-my-posh
    zsh
    lm_sensors
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

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.sw;
  basePackages = with pkgs; [
    tmux
    man
    (chromium.override {
      commandLineArgs = [ "--enable-features=TouchpadOverscrollHistoryNavigation" ];
    })
    lm_sensors
    zoom-us
    teams-for-linux
    wpsoffice
  ];
in {
  environment.systemPackages = subtractLists cfg.excludePackages (basePackages ++ cfg.extraPackages);

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.firefox.enable = true;
  programs.virt-manager.enable = true;
}

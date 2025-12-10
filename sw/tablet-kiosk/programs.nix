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
    libcamera
    chromium
    glib
    squeekboard
    dconf
    phoc
    gsettings-desktop-schemas
  ];
in
{
  environment.systemPackages = subtractLists cfg.excludePackages (basePackages ++ cfg.extraPackages);

  programs.chromium = {
    enable = true;
  };
}

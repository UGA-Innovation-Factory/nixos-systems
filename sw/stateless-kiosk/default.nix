{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
lib.mkMerge [
  (import ./kiosk-browser.nix {
    inherit
      config
      lib
      pkgs
      inputs
      ;
  })
  (import ./net.nix {
    inherit
      config
      lib
      pkgs
      inputs
      ;
  })
  {
    services.openssh.enable = false;
  }
]

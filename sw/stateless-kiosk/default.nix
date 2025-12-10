# This module defines the software stack for a stateless kiosk.
# It includes a custom Firefox wrapper, Cage (Wayland kiosk compositor), and specific networking configuration.
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

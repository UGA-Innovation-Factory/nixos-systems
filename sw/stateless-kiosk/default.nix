## This module defines the software stack for a stateless kiosk.
# It now uses Sway (Wayland compositor) and Chromium in kiosk mode.
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
  (import ./services.nix {
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
  (import ./programs.nix {
    inherit
      config
      lib
      pkgs
      inputs
      ;
  })
]

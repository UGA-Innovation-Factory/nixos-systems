# ============================================================================
# Desktop Software Configuration
# ============================================================================
# Imports desktop-specific programs and services (KDE Plasma, CUPS, etc.)

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
lib.mkMerge [
  (import ./programs.nix {
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
]

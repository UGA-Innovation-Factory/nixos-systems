# ============================================================================
# Headless Software Configuration
# ============================================================================
# Imports headless-specific programs and services (SSH, minimal CLI tools)

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

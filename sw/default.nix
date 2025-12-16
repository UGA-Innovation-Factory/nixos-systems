{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# ============================================================================
# Software Module Entry Point
# ============================================================================
# This module manages the software configuration for the system. It provides
# options to select the system type ('desktop' or 'kiosk') and handles
# the conditional importation of the appropriate sub-modules.

with lib;

let
  cfg = config.ugaif.sw;
in
{
  imports = [
    ./python.nix
    ./ghostty.nix
    ./updater.nix
  ];

  options.ugaif.sw = {
    enable = mkEnableOption "Standard Workstation Configuration";

    type = mkOption {
      type = types.enum [
        "desktop"
        "tablet-kiosk"
        "headless"
        "stateless-kiosk"
      ];
      default = "desktop";
      description = "Type of system configuration: 'desktop' for normal OS, 'tablet-kiosk' for tablet/kiosk mode.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages to install.";
    };

    excludePackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Packages to exclude from the default list.";
    };

    kioskUrl = mkOption {
      type = types.str;
      default = "https://ha.factory.uga.edu";
      description = "URL to open in Chromium kiosk mode.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # ========== System-Wide Configuration ==========
      nixpkgs.config.allowUnfree = true;

      # ========== Shell Configuration ==========
      programs.zsh.enable = true;
      programs.nix-ld.enable = true; # Allow running non-NixOS binaries

      # ========== Base Packages ==========
      environment.systemPackages =
        with pkgs;
        subtractLists cfg.excludePackages [
          htop # System monitor
          binutils # Binary utilities
          zsh # Z shell
          git # Version control
          oh-my-posh # Shell prompt theme
          inputs.agenix.packages.${stdenv.hostPlatform.system}.default # Secret management
        ];
    }
    # ========== Software Profile Imports ==========
    (mkIf (cfg.type == "desktop") (
      import ./desktop {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
    (mkIf (cfg.type == "tablet-kiosk") (
      import ./tablet-kiosk {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
    (mkIf (cfg.type == "headless") (
      import ./headless {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
    (mkIf (cfg.type == "stateless-kiosk") (
      import ./stateless-kiosk {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
  ]);
}

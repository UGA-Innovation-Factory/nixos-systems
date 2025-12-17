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

  # Normalize type to always be a list
  swTypes = if isList cfg.type then cfg.type else [ cfg.type ];

  # Helper to check if a type is enabled
  hasType = type: elem type swTypes;
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
      type = types.oneOf [
        (types.enum [
          "desktop"
          "tablet-kiosk"
          "headless"
          "stateless-kiosk"
          "builders"
        ])
        (types.listOf (
          types.enum [
            "desktop"
            "tablet-kiosk"
            "headless"
            "stateless-kiosk"
            "builders"
          ]
        ))
      ];
      default = "desktop";
      description = "Type(s) of system configuration. Can be a single type or a list of types to combine multiple configurations.";
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

    # Builders-specific options
    builders = mkOption {
      type = types.submodule {
        options = {
          githubRunner = {
            enable = mkEnableOption "GitHub Actions self-hosted runner";

            url = mkOption {
              type = types.str;
              description = "GitHub repository URL for the runner";
            };

            tokenFile = mkOption {
              type = types.path;
              default = "/var/lib/github-runner-token";
              description = ''
                Path to file containing GitHub PAT token.
                Generate at: https://github.com/settings/tokens
                The token must have repo access.
              '';
            };

            extraLabels = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Extra labels to identify this runner in workflows";
            };

            user = mkOption {
              type = types.str;
              default = "engr-ugaif";
              description = "User to run the runner as";
            };

            workDir = mkOption {
              type = types.str;
              default = "/var/lib/github-runner";
              description = "Working directory for runner";
            };

            name = mkOption {
              type = types.str;
              default = "nixos-systems";
              description = "Name of the GitHub runner service";
            };

            replace = mkOption {
              type = types.bool;
              default = false;
              description = "Replace existing runner registration on start";
            };
          };
        };
      };
      default = { };
      description = "Builder-specific configuration options";
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
    (mkIf (hasType "desktop") (
      import ./desktop {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
    (mkIf (hasType "tablet-kiosk") (
      import ./tablet-kiosk {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
    (mkIf (hasType "headless") (
      import ./headless {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
    (mkIf (hasType "stateless-kiosk") (
      import ./stateless-kiosk {
        inherit
          config
          lib
          pkgs
          inputs
          ;
      }
    ))
    (mkIf (hasType "builders") (
      import ./builders {
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

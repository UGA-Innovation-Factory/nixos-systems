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
  cfg = config.modules.sw;
in
{
  imports = [
    ./python.nix
    ./ghostty.nix
  ];

  options.modules.sw = {
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
      nixpkgs.config.allowUnfree = true;

      programs.zsh.enable = true;
      programs.nix-ld.enable = true;

      environment.systemPackages =
        with pkgs;
        subtractLists cfg.excludePackages [
          htop
          binutils
          zsh
          git
          oh-my-posh
          inputs.lazyvim-nixvim.packages.${stdenv.hostPlatform.system}.nvim
          # Custom update script
          (writeShellScriptBin "update-system" ''
            HOSTNAME=$(hostname)
            FLAKE_URI="github:UGA-Innovation-Factory/nixos-systems"

            # Pass arguments like --impure to nixos-rebuild
            EXTRA_ARGS="$@"

            if [[ "$HOSTNAME" == nix-surface* ]]; then
              echo "Detected Surface tablet. Using remote build host."
              sudo nixos-rebuild switch --flake "$FLAKE_URI" --build-host engr-ugaif@192.168.11.133 --refresh $EXTRA_ARGS
            else
              echo "Updating local system..."
              sudo nixos-rebuild switch --flake "$FLAKE_URI" --refresh $EXTRA_ARGS
            fi
          '')
        ];
    }
    # Import Desktop or Kiosk modules based on type
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

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.sw;
in
{
  imports = [
    ./python.nix
  ];

  options.modules.sw = {
    enable = mkEnableOption "Standard Workstation Configuration";

    type = mkOption {
      type = types.enum [ "desktop" "kiosk" ];
      default = "desktop";
      description = "Type of system configuration: 'desktop' for normal OS, 'kiosk' for tablet/kiosk mode.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Extra packages to install.";
    };

    excludePackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Packages to exclude from the default list.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      nixpkgs.config.allowUnfree = true;
      
      programs.zsh.enable = true;
      programs.nix-ld.enable = true;

      environment.systemPackages = with pkgs; subtractLists cfg.excludePackages [
        htop
        binutils
        zsh
        git
        oh-my-posh
        inputs.lazyvim-nixvim.packages.${stdenv.hostPlatform.system}.nvim
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
    (mkIf (cfg.type == "desktop") (import ./desktop { inherit config lib pkgs inputs; }))
    (mkIf (cfg.type == "kiosk") (import ./kiosk { inherit config lib pkgs inputs; }))
  ]);
}

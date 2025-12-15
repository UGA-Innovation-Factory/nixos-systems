# ============================================================================
# NixOS Modules Export
# ============================================================================
# This file exposes host types and software configurations as reusable NixOS 
# modules that can be imported by external flakes or configurations.
#
# Usage in another flake:
#   # Full host type configurations (includes hardware + software + system config)
#   inputs.nixos-systems.nixosModules.nix-desktop
#   inputs.nixos-systems.nixosModules.nix-laptop
#   
#   # Software-only configurations (for custom hardware setups)
#   inputs.nixos-systems.nixosModules.sw-desktop
#   inputs.nixos-systems.nixosModules.sw-headless

{ inputs }:
let
  # Software modules with their dependencies bundled
  mkSwModule = swType: { config, lib, pkgs, ... }: {
    imports = [
      ../sw/ghostty.nix
      ../sw/nvim.nix
      ../sw/python.nix
      ../sw/theme.nix
      (import ../sw/${swType} { inherit config lib pkgs inputs; })
    ];
  };
in
{
  # Host type modules (full system configurations)
  nix-desktop = import ../hosts/types/nix-desktop.nix { inherit inputs; };
  nix-laptop = import ../hosts/types/nix-laptop.nix { inherit inputs; };
  nix-surface = import ../hosts/types/nix-surface.nix { inherit inputs; };
  nix-lxc = import ../hosts/types/nix-lxc.nix { inherit inputs; };
  nix-wsl = import ../hosts/types/nix-wsl.nix { inherit inputs; };
  nix-ephemeral = import ../hosts/types/nix-ephemeral.nix { inherit inputs; };

  # Software-only modules (for mixing with custom hardware configs)
  sw-desktop = mkSwModule "desktop";
  sw-headless = mkSwModule "headless";
  sw-stateless-kiosk = mkSwModule "stateless-kiosk";
  sw-tablet-kiosk = mkSwModule "tablet-kiosk";
}

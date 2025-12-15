# ============================================================================
# Host Type Modules Export
# ============================================================================
# This file exposes each host type as a reusable NixOS module that can be
# imported by external flakes or configurations.
#
# Usage in another flake:
#   inputs.nixos-systems.nixosModules.nix-desktop
#   inputs.nixos-systems.nixosModules.nix-laptop
#   etc.

{ inputs }:
{
  nix-desktop = import ../hosts/types/nix-desktop.nix { inherit inputs; };
  nix-laptop = import ../hosts/types/nix-laptop.nix { inherit inputs; };
  nix-surface = import ../hosts/types/nix-surface.nix { inherit inputs; };
  nix-lxc = import ../hosts/types/nix-lxc.nix { inherit inputs; };
  nix-wsl = import ../hosts/types/nix-wsl.nix { inherit inputs; };
  nix-ephemeral = import ../hosts/types/nix-ephemeral.nix { inherit inputs; };
}

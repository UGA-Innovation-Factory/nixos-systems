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
#   # Note: These include theme.nix in home-manager.sharedModules automatically
#   inputs.nixos-systems.nixosModules.sw-desktop
#   inputs.nixos-systems.nixosModules.sw-headless
#
#   # Home Manager modules (user-level configuration)
#   # Theme module (no parameters):
#   home-manager.users.myuser.imports = [ inputs.nixos-systems.homeManagerModules.theme ];
#
#   # Neovim module (requires user parameter):
#   home-manager.users.myuser.imports = [
#     (inputs.nixos-systems.homeManagerModules.nvim {
#       user = config.ugaif.users.accounts.myuser;
#     })
#   ];

{ inputs }:
let
  # Helper function to create software-only modules
  # Bundles common system-level software with profile-specific config
  mkSwModule =
    swType:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        ../sw/ghostty.nix # Terminal emulator
        ../sw/python.nix # Python environment
        (import ../sw/${swType} {
          inherit
            config
            lib
            pkgs
            inputs
            ;
        })
      ];

      # Apply Home Manager modules to all users via sharedModules
      # This ensures consistent shell theme across all users
      home-manager.sharedModules = [
        ../sw/theme.nix
      ];
    };

  # Helper to create a Home Manager module for nvim (requires user context)
  # External users can import this with their user data
  mkNvimModule = user: (import ../sw/nvim.nix { inherit user; });
in
{
  # ========== Full Host Type Modules ==========
  # Complete system configurations including hardware, boot, and software
  nix-desktop = import ../hosts/types/nix-desktop.nix { inherit inputs; }; # Desktop workstations
  nix-laptop = import ../hosts/types/nix-laptop.nix { inherit inputs; }; # Laptop systems
  nix-surface = import ../hosts/types/nix-surface.nix { inherit inputs; }; # Surface tablets
  nix-lxc = import ../hosts/types/nix-lxc.nix { inherit inputs; }; # Proxmox containers
  nix-wsl = import ../hosts/types/nix-wsl.nix { inherit inputs; }; # WSL2 systems
  nix-ephemeral = import ../hosts/types/nix-ephemeral.nix { inherit inputs; }; # Diskless/RAM-only

  # ========== Software-Only Modules (NixOS) ==========
  # For use with custom hardware configurations
  sw-desktop = mkSwModule "desktop"; # Full desktop environment
  sw-headless = mkSwModule "headless"; # CLI-only systems
  sw-stateless-kiosk = mkSwModule "stateless-kiosk"; # Netboot kiosk
  sw-tablet-kiosk = mkSwModule "tablet-kiosk"; # Touch-based kiosk

  # ========== Home Manager Modules ==========
  # User-level configuration modules
  # Usage: home-manager.users.myuser.imports = [ (inputs.nixos-systems.homeManagerModules.nvim { user = <user-data>; }) ];
  homeModules = {
    theme = ../sw/theme.nix; # Zsh theme (no params needed)
    nvim = mkNvimModule; # Neovim (requires user param)
  };
}

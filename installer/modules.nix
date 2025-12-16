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
{
  # ========== Full Host Type Modules ==========
  # Complete system configurations including hardware, boot, and software
  nix-desktop = import ../hosts/types/nix-desktop.nix { inherit inputs; }; # Desktop workstations
  nix-laptop = import ../hosts/types/nix-laptop.nix { inherit inputs; }; # Laptop systems
  nix-surface = import ../hosts/types/nix-surface.nix { inherit inputs; }; # Surface tablets
  nix-lxc = import ../hosts/types/nix-lxc.nix { inherit inputs; }; # Proxmox containers
  nix-wsl = import ../hosts/types/nix-wsl.nix { inherit inputs; }; # WSL2 systems
  nix-ephemeral = import ../hosts/types/nix-ephemeral.nix { inherit inputs; }; # Diskless/RAM-only

  # ========== Software Configuration Module ==========
  # Main software module with all ugaif.sw options
  # Use ugaif.sw.type to select profile: "desktop", "tablet-kiosk", "headless", "stateless-kiosk"
  # Use ugaif.sw.extraPackages to add additional packages
  # Use ugaif.sw.kioskUrl to set kiosk mode URL
  sw =
    { inputs, ... }@args:
    (import ../sw/default.nix (args // { inherit inputs; }));
}

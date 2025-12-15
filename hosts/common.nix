# ============================================================================
# Common Modules
# ============================================================================
# This module contains all the common configuration shared by all host types.
# It includes:
# - Boot and user configuration
# - Software configurations
# - User management (users.nix)
# - Home Manager integration
# - Secret management (agenix)
# - Disk partitioning (disko)
# - System-wide Nix settings (experimental features, garbage collection)

{ inputs }:
{
  config,
  lib,
  ...
}:
{
  imports = [
    ./boot.nix
    ./user-config.nix
    ../sw
    ../users.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
  ];

  system.stateVersion = "25.11";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Automatic Garbage Collection
  nix.gc = lib.mkIf config.ugaif.system.gc.enable {
    automatic = true;
    dates = config.ugaif.system.gc.frequency;
    options = "--delete-older-than ${toString config.ugaif.system.gc.retentionDays}d";
  };

  # Optimize storage
  nix.optimise.automatic = config.ugaif.system.gc.optimise;
}

# Example Darwin Common Configuration
# This file shows what darwin-common.nix would look like
# File location: hosts/darwin-common.nix

{ inputs }:
{ config, lib, ... }:
{
  imports = [
    # user-config.nix works on both platforms
    ./user-config.nix
    
    # darwin-system.nix instead of boot.nix
    ./darwin-system.nix
    
    # Software profiles with platform detection
    ../sw
    
    # Home Manager (works on both platforms)
    inputs.home-manager.darwinModules.home-manager
  ];

  # System version (like stateVersion for NixOS)
  system.stateVersion = 4;

  # Nix settings (similar to NixOS)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Garbage collection (similar to NixOS)
  nix.gc = lib.mkIf config.ugaif.system.gc.enable {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };  # launchd format: Sunday at 3 AM
    options = "--delete-older-than ${toString config.ugaif.system.gc.retentionDays}d";
  };

  # Optimize storage
  nix.optimise.automatic = config.ugaif.system.gc.optimise;
}

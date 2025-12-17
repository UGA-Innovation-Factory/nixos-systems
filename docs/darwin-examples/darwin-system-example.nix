# Example Darwin System Configuration
# This file shows what darwin-system.nix would look like (replaces boot.nix)
# File location: hosts/darwin-system.nix

{ config, lib, ... }:
{
  # No boot configuration on Darwin (macOS handles this)
  # No disko configuration (uses existing macOS partitions)
  
  options.ugaif = {
    # Keep the forUser convenience option
    forUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Convenience option to configure a host for a specific user.
        Automatically adds the user to extraUsers.
      '';
    };

    host = {
      useHostPrefix = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to prepend the host prefix to the hostname.";
      };
      
      # No filesystem options on Darwin
      # No buildMethods (or empty list)
      buildMethods = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Build methods (none for Darwin)";
      };
    };

    # Garbage collection options (same as NixOS)
    system.gc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable automatic garbage collection.";
      };
      frequency = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "How often to run garbage collection.";
      };
      retentionDays = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Number of days to keep old generations.";
      };
      optimise = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to automatically optimize the Nix store.";
      };
    };
  };

  config = {
    # Set timezone (similar to NixOS)
    time.timeZone = "America/New_York";

    # macOS-specific system defaults
    system.defaults = {
      # Login window settings
      loginwindow = {
        GuestEnabled = false;
        DisableConsoleAccess = true;
      };

      # Security settings
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      # System UI settings
      NSGlobalDomain = {
        AppleInterfaceStyle = lib.mkDefault "Dark";  # Dark mode
        AppleShowAllFiles = false;
      };
    };

    # Services configuration (launchd instead of systemd)
    # This is where background services would be configured
    # Example: system updater as a launchd daemon
  };
}

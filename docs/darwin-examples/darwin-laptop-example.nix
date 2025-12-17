# Example Darwin Laptop Host Type
# This file shows what a darwin-laptop.nix would look like
# File location: hosts/types/darwin-laptop.nix

{ inputs, ... }:
{ config, lib, ... }:
{
  imports = [
    # Would import darwin-common.nix instead of linux-common.nix
    (import ../darwin-common.nix { inherit inputs; })
  ];

  # ========== Platform Configuration ==========
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";  # or "x86_64-darwin"

  # ========== macOS System Defaults ==========
  # These replace Linux boot/kernel settings
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      mru-spaces = false;  # Don't rearrange spaces by recent use
      show-recents = false;
      tilesize = 48;
    };

    # Global macOS settings
    NSGlobalDomain = {
      # Keyboard
      AppleKeyboardUIMode = 3;  # Full keyboard access
      ApplePressAndHoldEnabled = false;  # Disable press-and-hold for keys
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      
      # Interface
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Automatic";
      
      # Trackpad
      "com.apple.trackpad.scaling" = 2.0;
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    # Screen saver settings
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };
  };

  # ========== Power Management ==========
  # Replaces services.upower and logind settings
  # These are built into macOS but can be configured via defaults
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = true;

  # ========== Software Profile ==========
  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "desktop";
  
  # No build methods for Darwin (no ISOs, containers)
  ugaif.host.buildMethods = lib.mkDefault [ ];
}

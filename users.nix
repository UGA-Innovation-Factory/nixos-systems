{ pkgs, ... }:
{
  # ============================================================================
  # User Definitions
  # ============================================================================
  # This file defines the available user accounts. These accounts are NOT
  # enabled by default on all systems. They must be enabled via the
  # 'ugaif.users.enabledUsers' option in inventory.nix or system flakes.

  # Define the users here using the new option
  # To generate a password hash, run: mkpasswd -m sha-512
  # Set enabled = true on systems where the user should exist
  #
  # External User Configuration:
  # Users can specify external configuration modules via the 'external' attribute:
  #   external = builtins.fetchGit { url = "..."; rev = "..."; };
  #   external = /path/to/local/config;
  #
  # External repositories should contain:
  #   - user.nix (required): Defines ugaif.users.<name> options AND home-manager config
  #   - nixos.nix (optional): System-level NixOS configuration
  #
  # The user.nix file is imported in TWO contexts:
  #   1. As a NixOS module to read ugaif.users.<name> options (account settings)
  #   2. As a home-manager module for home.*, programs.*, services.* (user environment)
  #
  # User options can be set in users.nix OR in the external module's user.nix.
  # External module options take precedence over users.nix defaults.
  ugaif.users = {
    root = {
      isNormalUser = false;
      hashedPassword = "!";
      enable = true; # Root is always enabled
    };
    engr-ugaif = {
      description = "UGA Innovation Factory";
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "input"
      ];
      hashedPassword = "$6$El6e2NhPrhVFjbFU$imlGZqUiizWw5fMP/ib0CeboOcFhYjIVb8oR1V1dP2NjDeri3jMoUm4ZABOB2uAF8UEDjAGHhFuZxhtbHg647/";
      opensshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBC7xzHxY2BfFUybMvG4wHSF9oEAGzRiLTFEndLvWV/X hdh20267@engr733847d.engr.uga.edu"
      ];
      enable = true; # Default user, enabled everywhere
    };
    hdh20267 = {
      external = builtins.fetchGit {
        url = "https://git.factory.uga.edu/hdh20267/hdh20267-nix";
        rev = "db96137bb4cb16acefcf59d58c9f848924f2ad43";
      };
    };
    sv22900 = {
      description = "Alireza Vaezi";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.zsh;
      # enable = false by default, set to true per-system
    };
  };
}

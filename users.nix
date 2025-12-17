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
  # External Home Configuration:
  # Users can specify external home-manager configuration via the 'home' attribute:
  #   home = builtins.fetchGit { url = "..."; rev = "..."; };
  #   home = /path/to/local/config;
  #   home = { home.packages = [ ... ]; };  # Direct attrset
  #
  # External repositories should contain:
  #   - home.nix (required): Home-manager configuration
  #   - nixos.nix (optional): System-level NixOS configuration
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
      description = "Hunter Halloran";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      home = builtins.fetchGit {
        url = "https://git.factory.uga.edu/hdh20267/hdh20267-nix";
        rev = "ea99aa55680cc937f186aef0efc0df307e79d56f";
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

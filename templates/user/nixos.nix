{ inputs, ... }:

# ============================================================================
# User NixOS System Configuration (Optional)
# ============================================================================
# This file provides system-level NixOS configuration for a user.
# It's optional - most user configuration should go in home.nix.
#
# Use this for:
# - System-level services that depend on the user (e.g., user systemd services)
# - Special system permissions or configurations
# - Installing system packages that require root
#
# Note: User options (description, shell, extraGroups, etc.) should be set
# in your external module's user.nix or in the main users.nix file, not in
# this nixos.nix.
#
# This module receives the same `inputs` flake inputs as the main
# nixos-systems configuration.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ========== System Configuration ==========

  # Example: Enable a system service for this user
  # systemd.services.my-user-service = {
  #   description = "My User Service";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "myusername";
  #     ExecStart = "${pkgs.bash}/bin/bash -c 'echo Hello'";
  #   };
  # };

  # Example: Install system-wide packages needed by this user
  # environment.systemPackages = with pkgs; [
  #   docker
  # ];

  # Example: Add user to additional groups
  # users.users.myusername.extraGroups = [ "docker" ];

  # Most configuration should be in home.nix instead of here
}

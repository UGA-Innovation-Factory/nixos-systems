{ inputs, ... }:

# ============================================================================
# External System Module Template
# ============================================================================
# This is a template for creating external system configuration modules
# that can be referenced from nixos-systems/inventory.nix using builtins.fetchGit
#
# Usage in inventory.nix:
#   "my-type" = {
#     devices = {
#       "hostname" = builtins.fetchGit {
#         url = "https://github.com/your-org/your-config-repo";
#         rev = "commit-hash";
#       };
#     };
#   };
#
# This module will receive the same `inputs` flake inputs as the main
# nixos-systems configuration, allowing you to use nixpkgs, home-manager, etc.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ========== Module Options ==========
  # Define any custom options your module needs
  options = {
    # Example: myorg.customOption = lib.mkOption { ... };
  };

  # ========== Module Configuration ==========
  config = {
    # Your system configuration goes here
    # This can include any NixOS options

    # Example: Set timezone
    # time.timeZone = "America/New_York";

    # Example: Install packages
    # environment.systemPackages = with pkgs; [
    #   vim
    #   git
    # ];

    # Example: Configure services
    # services.openssh.enable = true;

    # Example: Use ugaif options if available from nixos-systems
    # ugaif.users.myuser.enable = true;
  };
}

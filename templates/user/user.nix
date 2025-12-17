{ inputs, ... }:

# ============================================================================
# User Configuration (Optional)
# ============================================================================
# This file can configure BOTH:
# 1. User account options (ugaif.users.<username>) when imported as NixOS module
# 2. Home-manager configuration (home.*, programs.*, services.*) when imported
#    into home-manager
#
# This file is optional - if not present, the system will use the defaults
# from the main users.nix file. Use this file to override or extend those
# default user and home-manager options for this user.
#
# This module receives the same `inputs` flake inputs as the main
# nixos-systems configuration (nixpkgs, home-manager, etc.).

{
  config,
  lib,
  pkgs,
  osConfig ? null, # Only available in home-manager context
  ...
}:

{
  # ========== User Account Configuration ==========
  # These are imported as a NixOS module to set ugaif.users options
  # Replace "myusername" with your actual username

  ugaif.users.myusername = {
    description = "Your Full Name";

    extraGroups = [
      "wheel" # Sudo access
      "networkmanager" # Network configuration
      # "docker"         # Docker access (if needed)
    ];

    shell = pkgs.zsh;

    # Optional: Override editor
    # editor = pkgs.helix;

    # Optional: Disable system theme/nvim plugins
    # useZshTheme = false;
    # useNvimPlugins = false;

    # Optional: Add system-level packages
    # extraPackages = with pkgs; [ docker ];
  };

  # Note: You don't need to set 'enable = true' - that's controlled
  # per-host in inventory.nix

  # ========== Home Manager Configuration ==========
  # These are imported into home-manager for user environment
  # System theme (zsh) and nvim config are applied automatically based on flags above

  # Packages
  home.packages = with pkgs; [
    # Add your preferred packages here
    # ripgrep
    # fd
    # bat
  ];

  # ========== Programs ==========

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # ========== Shell Environment ==========

  home.sessionVariables = {
    # EDITOR is set automatically based on ugaif.users.*.editor
    # Add your custom environment variables here
  };

  # ========== Dotfiles ==========

  # You can manage dotfiles with home.file
  # home.file.".bashrc".source = ./dotfiles/bashrc;
  # home.file.".vimrc".source = ./dotfiles/vimrc;

  # Or use programs.* options for better integration
}

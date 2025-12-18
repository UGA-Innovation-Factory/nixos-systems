{ inputs, ... }:

# ============================================================================
# User Configuration
# ============================================================================
# This file configures BOTH:
# 1. User account options (ugaif.users.<username>)
# 2. Home-manager configuration (home.*, programs.*, services.*)
#
# The same file is imported in two contexts:
# - As a NixOS module to read ugaif.users.<username> options
# - As a home-manager module for user environment configuration
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
  # Replace "myusername" with your actual username

  ugaif.users.myusername = {
    description = "Your Full Name";
    shell = pkgs.zsh;
    hashedPassword = "!"; # Locked password - use SSH keys only

    extraGroups = [
      "wheel" # Sudo access
      "networkmanager" # Network configuration
      # "docker"       # Docker access (if needed)
    ];

    opensshKeys = [
      # Add your SSH public keys here
      # "ssh-ed25519 AAAA... user@machine"
    ];

    useZshTheme = true; # Apply system Zsh theme
    useNvimPlugins = true; # Apply system Neovim plugins
  };

  # Note: You don't need to set 'enable = true' - that's controlled
  # per-host in inventory.nix via ugaif.users.myusername.enable

  # ========== Home Manager Configuration ==========

  # Packages
  home.packages =
    with pkgs;
    [
      htop
      ripgrep
      fd
      bat
    ]
    ++ lib.optional (osConfig.ugaif.sw.type or null == "desktop") firefox;
  # Conditionally add packages based on system type

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

  # Zsh configuration
  programs.zsh = {
    enable = true;
    # System theme is applied automatically if useZshTheme = true
  };

  # ========== Shell Environment ==========

  home.sessionVariables = {
    EDITOR = "nvim";
    # Add your custom environment variables here
  };

  # ========== XDG Configuration ==========

  xdg.enable = true;

  # ========== Dotfiles ==========

  # You can manage dotfiles with home.file
  # home.file.".bashrc".source = ./config/bashrc;
  # home.file.".vimrc".source = ./config/vimrc;

  # Or use programs.* options for better integration (recommended)
}

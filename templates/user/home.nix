{ inputs, ... }:

# ============================================================================
# User Home Manager Configuration Template (Optional)
# ============================================================================
# This file provides home-manager configuration for a user.
# It will be imported into the NixOS system's home-manager configuration.
#
# This file is optional - if not present, no home-manager configuration
# will be loaded from this external module.
#
# Usage in users.nix:
#   myusername = {
#     # Set user options here OR in the external module's user.nix
#     description = "My Name";
#     shell = pkgs.zsh;
#     extraGroups = [ "wheel" "networkmanager" ];
#     
#     external = builtins.fetchGit {
#       url = "https://github.com/username/dotfiles";
#       rev = "commit-hash";
#     };
#   };
#
# Or use user.nix in your external module to set user options.
#
# This module receives the same `inputs` flake inputs as the main
# nixos-systems configuration (nixpkgs, home-manager, etc.).

{
  config,
  lib,
  pkgs,
  osConfig, # Access to the OS-level config
  ...
}:

{
  # ========== Home Manager Configuration ==========

  # User identity (required)
  home.username = lib.mkDefault config.home.username; # Set by system
  home.homeDirectory = lib.mkDefault config.home.homeDirectory; # Set by system
  home.stateVersion = lib.mkDefault "25.11";

  # ========== Packages ==========
  home.packages = with pkgs; [
    # Add your preferred packages here
    # htop
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

  # Zsh configuration
  programs.zsh = {
    enable = true;
    # System theme is applied automatically if useZshTheme = true in users.nix
    # Add your custom zsh config here
  };

  # Neovim configuration
  # programs.neovim = {
  #   enable = true;
  #   # System nvim config is applied automatically if useNvimPlugins = true
  #   # Add your custom neovim config here
  # };

  # ========== Shell Environment ==========

  home.sessionVariables = {
    EDITOR = "vim";
    # Add your custom environment variables
  };

  # ========== Dotfiles ==========

  # You can manage dotfiles with home.file
  # home.file.".bashrc".source = ./dotfiles/bashrc;
  # home.file.".vimrc".source = ./dotfiles/vimrc;

  # Or use programs.* options for better integration

  # ========== XDG Configuration ==========

  xdg.enable = true;
  # xdg.configFile."app/config.conf".source = ./config/app.conf;
}

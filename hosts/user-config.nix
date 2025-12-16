{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

# ============================================================================
# User Configuration Module
# ============================================================================
# This module defines the schema for user accounts and handles their creation.
# It bridges the gap between the data in 'users.nix' and the actual NixOS
# and Home Manager configuration.

let
  # Submodule defining the structure of a user account
  userSubmodule = lib.types.submodule {
    options = {
      isNormalUser = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      hashedPassword = lib.mkOption {
        type = lib.types.str;
        default = "!";
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };
      excludePackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };
      homePackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };
      extraImports = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
      };
      flakeUrl = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "URL of a flake to import Home Manager configuration from (e.g. github:user/dotfiles).";
      };
      opensshKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of SSH public keys for the user.";
      };
      shell = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "The shell for this user.";
      };
      editor = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "The default editor for this user.";
      };
      useZshTheme = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to apply the system Zsh theme.";
      };
      useNvimPlugins = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to apply the system Neovim configuration.";
      };
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this user account is enabled on this system.";
      };
    };
  };
in
{
  options.ugaif.users = lib.mkOption {
    type = lib.types.attrsOf userSubmodule;
    default = { };
    description = "User accounts configuration. Set enable=true for users that should exist on this system.";
  };

  config = {
    # Enable forUser if specified
    ugaif.users = lib.mkIf (config.ugaif.forUser != null) {
      ${config.ugaif.forUser}.enable = true;
    };

    # Generate NixOS users
    users.users =
      let
        enabledAccounts = lib.filterAttrs (_: user: user.enable) config.ugaif.users;
      in
      lib.mapAttrs (
        name: user:
        let
          isPlasma6 = config.services.desktopManager.plasma6.enable;
          defaultPackages = lib.optionals (isPlasma6 && name != "root") [ pkgs.kdePackages.kate ];
          finalPackages = lib.subtractLists user.excludePackages (defaultPackages ++ user.extraPackages);
        in
        {
          inherit (user) isNormalUser extraGroups hashedPassword;
          description = if user.description != null then user.description else lib.mkDefault "";
          openssh.authorizedKeys.keys = user.opensshKeys;
          packages = finalPackages;
          shell = if user.shell != null then user.shell else pkgs.bash;
        }
      ) enabledAccounts;

    # Home Manager configs per user
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        osConfig = config;
        inherit inputs;
      };

      users =
        let
          enabledAccounts = lib.filterAttrs (_: user: user.enable) config.ugaif.users;
        in
        lib.mapAttrs (
          name: user:
          { ... }:
          let
            isExternal = user.flakeUrl != "";

            # Common imports based on flags
            commonImports = lib.optional user.useZshTheme ../sw/theme.nix ++ [
              (import ../sw/nvim.nix { inherit user; })
            ];
          in
          if isExternal then
            {
              # External users: Only apply requested system modules.
              # The external flake is responsible for home.username, home.packages, etc.
              imports = commonImports;
            }
          else
            {
              # Local users: Apply full configuration.
              imports = user.extraImports ++ commonImports;
              home.username = name;
              home.homeDirectory = if name == "root" then "/root" else "/home/${name}";
              home.stateVersion = "25.11";
              home.packages = user.homePackages;
            }
        ) enabledAccounts;
    };
  };
}

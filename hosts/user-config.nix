{
  pkgs,
  config,
  lib,
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
    };
  };
in
{
  options.ugaif.users = {
    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.bash;
      description = "The default shell for users.";
    };
    accounts = lib.mkOption {
      type = lib.types.attrsOf userSubmodule;
      default = { };
      description = "User accounts configuration.";
    };
    enabledUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of users to enable on this system.";
    };
  };

  config = {
    # Default enabled users (always present)
    ugaif.users.enabledUsers = [
      "root"
      "engr-ugaif"
    ];

    # Generate NixOS users
    users.users =
      let
        enabledAccounts = lib.filterAttrs (
          name: _: lib.elem name config.ugaif.users.enabledUsers
        ) config.ugaif.users.accounts;
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
          shell = if user.shell != null then user.shell else config.ugaif.users.shell;
        }
      ) enabledAccounts;

    # Home Manager configs per user
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        osConfig = config;
      };

      users =
        let
          enabledAccounts = lib.filterAttrs (
            name: _: lib.elem name config.ugaif.users.enabledUsers
          ) config.ugaif.users.accounts;
        in
        lib.mapAttrs (
          name: user:
          { ... }:
          let
            isExternal = user.flakeUrl != "";

            # Common imports based on flags
            commonImports =
              lib.optional user.useZshTheme ../sw/theme.nix ++ lib.optional user.useNvimPlugins ../sw/nvim.nix;
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

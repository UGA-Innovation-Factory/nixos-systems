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
  # Load users.nix to get account definitions
  pkgs' = pkgs;
  usersData = import ../users.nix { pkgs = pkgs'; };
  accounts = usersData.ugaif.users or { };

  # Helper: Resolve external module path from fetchGit/fetchTarball/path
  resolveExternalPath =
    external:
    if external == null then
      null
    else if builtins.isAttrs external && external ? outPath then
      external.outPath
    else
      external;

  # Helper: Check if path exists and is valid
  isValidPath =
    path:
    path != null
    && (builtins.isPath path || (builtins.isString path && lib.hasPrefix "/" path))
    && builtins.pathExists path;

  # Extract ugaif.users options from external user.nix modules
  externalUserOptions = lib.foldl' (
    acc: item:
    let
      name = item.name;
      user = item.user;
      externalPath = resolveExternalPath (user.external or null);
      userNixPath = if externalPath != null then externalPath + "/user.nix" else null;

      # Load the module and extract its ugaif.users options
      moduleOptions =
        if isValidPath userNixPath then
          let
            # Import and evaluate the module with minimal args
            outerModule = import userNixPath { inherit inputs; };
            evaluatedModule = outerModule {
              config = { };
              inherit lib pkgs;
              osConfig = null;
            };
            # Extract just the ugaif.users.<name> options
            ugaifUsers = evaluatedModule.ugaif.users or { };
            userOptions = ugaifUsers.${name} or { };
          in
          userOptions
        else
          { };
    in
    if moduleOptions != { } then acc // { ${name} = moduleOptions; } else acc
  ) { } (lib.mapAttrsToList (name: user: { inherit name user; }) accounts);

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
      external = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.oneOf [
            lib.types.path
            lib.types.package
            lib.types.attrs
          ]
        );
        default = null;
        description = ''
          External user configuration module. Can be:
          - A path to a local module directory
          - A fetchGit/fetchTarball result pointing to a repository

          The external module can contain:
          - user.nix (optional): Sets ugaif.users.<name> options AND home-manager config
          - nixos.nix (optional): System-level NixOS configuration

          Example: builtins.fetchGit { url = "https://github.com/user/dotfiles"; rev = "..."; }
        '';
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
    # Merge user definitions from users.nix with options from external user.nix modules
    # External options take precedence over users.nix (which uses lib.mkDefault)
    ugaif.users = lib.mapAttrs (
      name: user:
      {
        description = lib.mkDefault (user.description or null);
        shell = lib.mkDefault (user.shell or null);
        extraGroups = lib.mkDefault (user.extraGroups or [ ]);
        external = user.external or null;
      }
      // (externalUserOptions.${name} or { })
    ) accounts;

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
          let
            # Resolve external module paths
            hasExternal = user.external != null;
            externalPath = resolveExternalPath user.external;
            userNixPath = if externalPath != null then externalPath + "/user.nix" else null;
            hasExternalUser = isValidPath userNixPath;

            # Import external user.nix for home-manager (filter out ugaif.* options)
            externalUserModule =
              if hasExternalUser then
                let
                  fullModule = import userNixPath { inherit inputs; };
                in
                # Only pass through non-ugaif options to home-manager
                {
                  config,
                  lib,
                  pkgs,
                  osConfig,
                  ...
                }:
                let
                  evaluated = fullModule {
                    inherit
                      config
                      lib
                      pkgs
                      osConfig
                      ;
                  };
                in
                lib.filterAttrs (name: _: name != "ugaif") evaluated
              else
                { };

            # Common imports based on user flags
            commonImports = lib.optional user.useZshTheme ../sw/theme.nix ++ [
              (import ../sw/nvim.nix { inherit user; })
            ];

            # Build imports list
            allImports = user.extraImports ++ commonImports ++ lib.optional hasExternalUser externalUserModule;
          in
          lib.mkMerge [
            {
              imports = allImports;

              # Always set these required options
              home.username = name;
              home.homeDirectory = if name == "root" then "/root" else "/home/${name}";
              home.stateVersion = "25.11";
            }
            (lib.mkIf (!hasExternal) {
              # For local users only, add their packages
              home.packages = user.homePackages;
            })
          ]
        ) enabledAccounts;
    };
  };
}

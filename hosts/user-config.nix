{ pkgs, config, lib, ... }:
let
  userSubmodule = lib.types.submodule {
    options = {
      isNormalUser = lib.mkOption { type = lib.types.bool; default = true; };
      description = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      extraGroups = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
      hashedPassword = lib.mkOption { type = lib.types.str; default = "!"; };
      extraPackages = lib.mkOption { type = lib.types.listOf lib.types.package; default = []; };
      excludePackages = lib.mkOption { type = lib.types.listOf lib.types.package; default = []; };
      homePackages = lib.mkOption { type = lib.types.listOf lib.types.package; default = []; };
      extraImports = lib.mkOption { type = lib.types.listOf lib.types.path; default = []; };
      flakeUrl = lib.mkOption { type = lib.types.str; default = ""; description = "URL of a flake to import Home Manager configuration from (e.g. github:user/dotfiles)."; };
      opensshKeys = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; description = "List of SSH public keys for the user."; };
    };
  };
in
{
  options.modules.users = {
    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zsh;
      description = "The default shell for users.";
    };
    accounts = lib.mkOption {
      type = lib.types.attrsOf userSubmodule;
      default = {};
      description = "User accounts configuration.";
    };
    enabledUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of users to enable on this system.";
    };
  };

  config = {
    modules.users.enabledUsers = [ "root" "engr-ugaif" ];

    # Generate NixOS users
    users.users = 
      let
        enabledAccounts = lib.filterAttrs (name: _: lib.elem name config.modules.users.enabledUsers) config.modules.users.accounts;
      in
      lib.mapAttrs (name: user: 
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
        shell = config.modules.users.shell;
      }
    ) enabledAccounts;
    
    # Home Manager configs per user
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { osConfig = config; };

      users = 
        let
          enabledAccounts = lib.filterAttrs (name: _: lib.elem name config.modules.users.enabledUsers) config.modules.users.accounts;
        in
        lib.mapAttrs (name: user: { ... }: {
          imports = user.extraImports ++ [ ../sw/theme.nix ../sw/nvim.nix ] ++
            (lib.optional (user.flakeUrl != "") (builtins.getFlake user.flakeUrl).homeManagerModules.default);
          home.username = name;
          home.homeDirectory = if name == "root" then "/root" else "/home/${name}";
          home.stateVersion = "25.11";
          home.packages = user.homePackages;
        }) enabledAccounts;
    };
  };
}

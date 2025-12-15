{
  inputs,
  hosts ? import ../inventory.nix,
  ...
}:

# ============================================================================
# Host Generator
# ============================================================================
# This file contains the logic to generate NixOS configurations for all hosts
# defined in inventory.nix. It handles:
# 1. Common module imports (boot, users, software).
# 2. Host-specific overrides (filesystem, enabled users).
# 3. External flake integration for system overrides.

let
  nixpkgs = inputs.nixpkgs;
  lib = nixpkgs.lib;
  home-manager = inputs.home-manager;
  agenix = inputs.agenix;
  disko = inputs.disko;

  # Modules shared by all hosts
  commonModules = [
    ./boot.nix
    ./user-config.nix
    ../users.nix
    ../sw
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    disko.nixosModules.disko
    {
      system.stateVersion = "25.11";
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Automatic Garbage Collection
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      # Optimize storage
      nix.optimise.automatic = true;
    }
  ];

  # Helper to create a single NixOS system configuration
  mkHost =
    {
      hostName,
      system ? "x86_64-linux",
      extraModules ? [ ],
    }:
    let
      # Load users.nix to find external user flakes
      # We use legacyPackages to evaluate the simple data structure of users.nix
      pkgs = nixpkgs.legacyPackages.${system};
      usersData = import ../users.nix { inherit pkgs; };
      accounts = usersData.ugaif.users.accounts or { };

      # Extract flakeUrls and convert to modules
      userFlakeModules = lib.mapAttrsToList (
        name: user:
        if (user ? flakeUrl && user.flakeUrl != "") then
          (builtins.getFlake user.flakeUrl).nixosModules.default
        else
          { }
      ) accounts;
      
      allModules =
        commonModules
        ++ userFlakeModules
        ++ extraModules
        ++ [
          { networking.hostName = hostName; }
        ];
    in
    {
      system = lib.nixosSystem {
        inherit system;

        specialArgs = { inherit inputs; };

        modules = allModules;
      };
      modules = allModules;
    };

  # Function to generate a set of hosts based on inventory count and overrides
  mkHostGroup =
    {
      prefix,
      count,
      system ? "x86_64-linux",
      extraModules ? [ ],
      deviceOverrides ? { },
    }:
    lib.listToAttrs (
      lib.concatMap (
        i:
        let
          defaultName = "${prefix}${toString i}";
          devConf = deviceOverrides.${toString i} or { };
          hasOverride = builtins.hasAttr (toString i) deviceOverrides;
          hostName =
            if hasOverride && (builtins.hasAttr "hostname" devConf) then devConf.hostname else defaultName;

          # Extract flakeUrl if it exists
          externalFlake =
            if hasOverride && (builtins.hasAttr "flakeUrl" devConf) then
              builtins.getFlake devConf.flakeUrl
            else
              null;

          # Module from external flake
          externalModule = if externalFlake != null then externalFlake.nixosModules.default else { };

          # Config override module (filesystem, users)
          overrideModule =
            { ... }:
            let
              # Extract device-specific config, removing special keys that need custom handling
              baseConfig = lib.removeAttrs devConf [
                "extraUsers"
                "flakeUrl"
                "hostname"
                "buildMethods"
                "wslUser"
              ];
              # Handle special keys that map to specific ugaif options
              specialConfig = lib.mkMerge [
                (lib.optionalAttrs (devConf ? extraUsers) { ugaif.users.enabledUsers = devConf.extraUsers; })
                (lib.optionalAttrs (devConf ? buildMethods) { ugaif.host.buildMethods = devConf.buildMethods; })
                (lib.optionalAttrs (devConf ? wslUser) { ugaif.host.wsl.user = devConf.wslUser; })
              ];
            in
            lib.mkIf hasOverride (lib.recursiveUpdate baseConfig specialConfig);

          config = mkHost {
            hostName = hostName;
            inherit system;
            extraModules =
              extraModules ++ [ overrideModule ] ++ (lib.optional (externalFlake != null) externalModule);
          };

          aliasNames = lib.optional (hostName != defaultName) hostName;
          names = lib.unique ([ defaultName ] ++ aliasNames);
        in
        lib.map (name: {
          inherit name;
          value = config;
        }) names
      ) (lib.range 1 count)
    );

  # Generate host groups based on the input hosts configuration
  hostGroups = lib.mapAttrsToList (
    type: config:
    let
      typeFile = ./types + "/${type}.nix";
      modules =
        if builtins.pathExists typeFile then
          import typeFile { inherit inputs; }
        else
          throw "Host type '${type}' not found in hosts/types/";
    in
    mkHostGroup {
      prefix = type;
      inherit (config) count;
      extraModules = modules;
      deviceOverrides = config.devices or { };
    }
  ) hosts;

  allHosts = lib.foldl' lib.recursiveUpdate { } hostGroups;
in
{
  nixosConfigurations = lib.mapAttrs (n: v: v.system) allHosts;
  modules = lib.mapAttrs (n: v: v.modules) allHosts;
}

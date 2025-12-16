{
  inputs,
  hosts ? import ../inventory.nix,
  ...
}:

# ============================================================================
# Host Generator
# ============================================================================
# This file contains the logic to generate NixOS configurations for all hosts
# defined in inventory.nix. It supports both hostname-based and count-based
# configurations with flexible type associations.
#
# Inventory format:
# {
#   "my-hostname" = {
#     type = "nix-desktop";  # Host type module to use
#     system = "x86_64-linux";  # Optional
#     # ... any ugaif.* options or device-specific config
#   };
#
#   "lab-prefix" = {
#     type = "nix-laptop";
#     count = 5;  # Generates lab-prefix1, lab-prefix2, ... lab-prefix5
#     devices = {
#       "machine-1" = { ... };  # Override for lab-prefix1
#     };
#   };
# }

let
  nixpkgs = inputs.nixpkgs;
  lib = nixpkgs.lib;
  # Helper to create a single NixOS system configuration
  mkHost =
    {
      hostName,
      system ? "x86_64-linux",
      hostType,
      configOverrides ? { },
    }:
    let
      # Load users.nix to find external user flakes
      pkgs = nixpkgs.legacyPackages.${system};
      usersData = import ../users.nix { inherit pkgs; };
      accounts = usersData.ugaif.users or { };

      # Extract flakeUrls and convert to modules
      userFlakeModules = lib.mapAttrsToList (
        name: user:
        if (user ? flakeUrl && user.flakeUrl != "") then
          (builtins.getFlake user.flakeUrl).nixosModules.default
        else
          { }
      ) accounts;

      # Load the host type module
      typeFile = ./types + "/${hostType}.nix";
      typeModule =
        if builtins.pathExists typeFile then
          import typeFile { inherit inputs; }
        else
          throw "Host type '${hostType}' not found in hosts/types/";

      # External flake override if specified
      externalFlakeModule =
        if configOverrides ? flakeUrl then
          (builtins.getFlake configOverrides.flakeUrl).nixosModules.default
        else
          { };

      # Config override module - translate special keys to ugaif options
      overrideModule =
        { ... }:
        let
          cleanConfig = lib.removeAttrs configOverrides [
            "type"
            "count"
            "devices"
            "overrides"
            "defaultCount"
            "extraUsers"
            "flakeUrl"
            "hostname"
            "buildMethods"
            "wslUser"
          ];
          specialConfig = lib.mkMerge [
            (lib.optionalAttrs (configOverrides ? extraUsers) {
              # Enable each user in the extraUsers list
              ugaif.users = lib.genAttrs configOverrides.extraUsers (_: { enable = true; });
            })
            (lib.optionalAttrs (configOverrides ? buildMethods) {
              ugaif.host.buildMethods = configOverrides.buildMethods;
            })
            (lib.optionalAttrs (configOverrides ? wslUser) {
              ugaif.host.wsl.user = configOverrides.wslUser;
            })
          ];
        in
        {
          config = lib.mkMerge [
            cleanConfig
            specialConfig
          ];
        };

      allModules =
        userFlakeModules
        ++ [
          typeModule
          overrideModule
          { networking.hostName = hostName; }
        ]
        ++ lib.optional (configOverrides ? flakeUrl) externalFlakeModule;
    in
    {
      system = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = allModules;
      };
      modules = allModules;
    };

  # Process inventory entries - top-level keys are always prefixes
  processInventory = lib.mapAttrs (
    prefix: config:
    let
      hostType = config.type or prefix;
      system = config.system or "x86_64-linux";
      devices = config.devices or { };
      hasCount = config ? count;

      # Helper to generate hostname from prefix and suffix
      # Numbers get no dash: "nix-surface1", "nix-surface2"
      # Letters get dash: "nix-surface-alpha", "nix-surface-beta"
      mkHostName =
        prefix: suffix: usePrefix:
        if !usePrefix then
          suffix
        else if lib.match "[0-9]+" suffix != null then
          "${prefix}${suffix}" # numeric: no dash
        else
          "${prefix}-${suffix}"; # non-numeric: add dash

      # Extract common overrides and default count
      overrides = config.overrides or { };
      defaultCount = config.defaultCount or 0;

      # If devices is a number, treat it as count
      devicesValue = config.devices or { };
      actualDevices = if lib.isInt devicesValue then { } else devicesValue;
      actualCount = if lib.isInt devicesValue then devicesValue else (config.count or 0);

      # Clean base config - remove inventory management keys
      baseConfig = lib.removeAttrs config [
        "type"
        "system"
        "count"
        "devices"
        "overrides"
        "defaultCount"
      ];

      # Generate hosts from explicit device definitions
      deviceHosts = lib.listToAttrs (
        lib.mapAttrsToList (
          deviceKey: deviceConfig:
          let
            usePrefix = deviceConfig.ugaif.host.useHostPrefix or true;
            hostName = mkHostName prefix deviceKey usePrefix;
            # Merge: base config -> overrides -> device-specific config
            mergedConfig = lib.recursiveUpdate (lib.recursiveUpdate baseConfig overrides) deviceConfig;
          in
          {
            name = hostName;
            value = mkHost {
              inherit hostName system hostType;
              configOverrides = mergedConfig;
            };
          }
        ) actualDevices
      );

      # Generate numbered hosts from count or defaultCount
      # If devices are specified, defaultCount fills in the gaps
      countToUse = if actualCount > 0 then actualCount else defaultCount;

      # Get which numbered keys are already defined in devices
      existingNumbers = lib.filter (k: lib.match "[0-9]+" k != null) (lib.attrNames actualDevices);

      countHosts =
        if countToUse > 0 then
          lib.listToAttrs (
            lib.filter (x: x != null) (
              map (
                i:
                let
                  deviceKey = toString i;
                  # Skip if this number is already in explicit devices
                  alreadyDefined = lib.elem deviceKey existingNumbers;
                in
                if alreadyDefined then
                  null
                else
                  let
                    hostName = mkHostName prefix deviceKey true;
                    mergedConfig = lib.recursiveUpdate baseConfig overrides;
                  in
                  {
                    name = hostName;
                    value = mkHost {
                      inherit hostName system hostType;
                      configOverrides = mergedConfig;
                    };
                  }
              ) (lib.range 1 countToUse)
            )
          )
        else
          { };
    in
    lib.recursiveUpdate deviceHosts countHosts
  ) hosts;

  # Flatten the nested structure
  allHosts = lib.foldl' lib.recursiveUpdate { } (lib.attrValues processInventory);
in
{
  nixosConfigurations = lib.mapAttrs (n: v: v.system) allHosts;
  modules = lib.mapAttrs (n: v: v.modules) allHosts;
}

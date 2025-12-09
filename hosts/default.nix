{ inputs, hosts ? import ../inventory.nix, ... }:

let
  nixpkgs      = inputs.nixpkgs;
  lib          = nixpkgs.lib;
  home-manager = inputs.home-manager;
  disko        = inputs.disko;

  commonModules = [
    ./boot.nix
    ./user-config.nix
    ../users.nix
    ../sw
    home-manager.nixosModules.home-manager
    disko.nixosModules.disko
    {
      system.stateVersion = "25.11";
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      
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

  mkHost = { hostName, system ? "x86_64-linux", extraModules ? [ ] }:
    lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules =
        commonModules
        ++ extraModules
        ++ [
          { networking.hostName = hostName; }
        ];
    };

  # Function to generate a set of hosts
  mkHostGroup = { prefix, count, system ? "x86_64-linux", extraModules ? [], deviceOverrides ? {} }:
    lib.listToAttrs (map (i: {
      name = "${prefix}${toString i}";
      value = 
        let
          devConf = deviceOverrides.${toString i} or {};
          hasOverride = builtins.hasAttr (toString i) deviceOverrides;
          
          # Extract flakeUrl if it exists
          externalFlake = if hasOverride && (builtins.hasAttr "flakeUrl" devConf) 
                          then builtins.getFlake devConf.flakeUrl 
                          else null;
          
          # Module from external flake
          externalModule = if externalFlake != null 
                           then externalFlake.nixosModules.default 
                           else {};

          # Config override module
          overrideModule = { ... }: 
            let
              # Remove special keys that are not filesystem options
              fsConf = builtins.removeAttrs devConf [ "extraUsers" "flakeUrl" ];
            in lib.mkIf hasOverride {
              host.filesystem = fsConf;
              modules.users.enabledUsers = devConf.extraUsers or [];
            };
        in
        mkHost {
          hostName = "${prefix}${toString i}";
          inherit system;
          extraModules = extraModules ++ [ overrideModule ] ++ (lib.optional (externalFlake != null) externalModule);
        };
    }) (lib.range 1 count));

  # Generate host groups based on the input hosts configuration
  hostGroups = lib.mapAttrsToList (type: config:
    let
      typeFile = ./types + "/${type}.nix";
      modules = if builtins.pathExists typeFile 
                then import typeFile { inherit inputs; }
                else throw "Host type '${type}' not found in hosts/types/";
    in
      mkHostGroup {
        prefix = type;
        inherit (config) count;
        extraModules = modules;
        deviceOverrides = config.devices or {};
      }
  ) hosts;

in
  lib.foldl' lib.recursiveUpdate {} hostGroups

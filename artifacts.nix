{ inputs, hosts, self, system }:
let
  nixpkgs = inputs.nixpkgs;
  lib = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.${system};
  nixos-generators = inputs.nixos-generators;

  mkInstaller = hostName:
    let
      targetConfig = self.nixosConfigurations.${hostName}.config;
      targetSystem = targetConfig.system.build.toplevel;
      diskoScript = targetConfig.system.build.diskoScript;
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs hostName targetSystem diskoScript;
        hostPlatform = system;
      };
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        inputs.disko.nixosModules.disko
        ./installer/auto-install.nix
      ];
    };

  mkGenerator = hostName: format:
    nixos-generators.nixosGenerate {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = hosts.modules.${hostName} ++ [
        {
          disko.enableConfig = lib.mkForce false;
          services.upower.enable = lib.mkForce false;
        }
      ];
      inherit format;
    };

  mkNetboot = hostName:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = hosts.modules.${hostName} ++ [
        "${nixpkgs}/nixos/modules/installer/netboot/netboot.nix"
        {
          disko.enableConfig = lib.mkForce false;
          services.upower.enable = lib.mkForce false;
        }
      ];
    };

  hostNames = builtins.attrNames hosts.nixosConfigurations;

  installerPackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "installer-iso" cfg.config.host.buildMethods then [{
      name = "installer-iso-${name}";
      value = (mkInstaller name).config.system.build.isoImage;
    }] else []
  ) hostNames);

  isoPackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "iso" cfg.config.host.buildMethods then [{
      name = "iso-${name}";
      value = mkGenerator name "iso";
    }] else []
  ) hostNames);

  ipxePackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "ipxe" cfg.config.host.buildMethods then [{
      name = "ipxe-${name}";
      value =
        let
          build = (mkNetboot name).config.system.build;
        in
        pkgs.symlinkJoin {
          name = "netboot-artifacts-${name}";
          paths = [
            build.netbootRamdisk
            build.kernel
            build.netbootIpxeScript
          ];
        };
    }] else []
  ) hostNames);

  lxcPackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "lxc" cfg.config.host.buildMethods then [{
      name = "lxc-${name}";
      value =
        if cfg.config.boot.isContainer then
          cfg.config.system.build.tarball
        else
          mkGenerator name "lxc";
    }] else []
  ) hostNames);

  proxmoxPackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "proxmox" cfg.config.host.buildMethods then [{
      name = "proxmox-${name}";
      value =
        if cfg.config.boot.isContainer then
          cfg.config.system.build.tarball
        else
          mkGenerator name "proxmox";
    }] else []
  ) hostNames);
in
installerPackages // isoPackages // ipxePackages // lxcPackages // proxmoxPackages

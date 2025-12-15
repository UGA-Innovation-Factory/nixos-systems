{ inputs, hosts, self, system }:
# This file defines the logic for generating various build artifacts (ISOs, Netboot, LXC, etc.)
# It exports a set of packages that can be built using `nix build .#<artifact-name>`
let
  nixpkgs = inputs.nixpkgs;
  lib = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.${system};
  nixos-generators = inputs.nixos-generators;

  # Creates a self-installing ISO for a specific host configuration
  # This ISO will automatically partition the disk (using disko) and install the system
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
        ./auto-install.nix
      ];
    };

  # Uses nixos-generators to create artifacts like LXC containers, Proxmox VMA, or Live ISOs
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

  # Creates Netboot (iPXE) artifacts using the native NixOS netboot module
  # Returns a system configuration that includes the netboot module
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

  # Generate installer ISOs for hosts that have "installer-iso" in their buildMethods
  installerPackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "installer-iso" cfg.config.components.host.buildMethods then [{
      name = "installer-iso-${name}";
      value = (mkInstaller name).config.system.build.isoImage;
    }] else []
  ) hostNames);

  # Generate Live ISOs for hosts that have "iso" in their buildMethods
  isoPackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "iso" cfg.config.components.host.buildMethods then [{
      name = "iso-${name}";
      value = mkGenerator name "iso";
    }] else []
  ) hostNames);

  # Generate iPXE artifacts (kernel, initrd, script) for hosts that have "ipxe" in their buildMethods
  ipxePackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "ipxe" cfg.config.components.host.buildMethods then [{
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

  # Generate LXC tarballs for hosts that have "lxc" in their buildMethods
  lxcPackages = lib.listToAttrs (lib.concatMap (name:
    let cfg = hosts.nixosConfigurations.${name}; in
    if lib.elem "lxc" cfg.config.components.host.buildMethods then [{
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
    if lib.elem "proxmox" cfg.config.components.host.buildMethods then [{
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

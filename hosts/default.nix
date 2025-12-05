{ inputs, ... }:

let
  nixpkgs      = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  disko        = inputs.disko;
  lib          = nixpkgs.lib;

  commonModules = [
    ../boot.nix
    ../users
    home-manager.nixosModules.home-manager
    disko.nixosModules.disko
    ({ ... }: {
      disko.enableConfig = true;

      disko.devices = {
        disk.main = {
          type = "disk";
          device = lib.mkDefault "/dev/nvme0n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                name = "ESP";
                label = "BOOT";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                  extraArgs = [ "-n" "BOOT" ];
                };
              };

              swap = {
                name = "swap";
                label = "swap";
                size = lib.mkDefault "34G";
                content = { type = "swap"; };
              };

              root = {
                name = "root";
                label = "root";
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  extraArgs = [ "-L" "ROOT" ];
                };
              };
            };
          };
        };
      };
    })
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
in
{
  nix-laptop1 = mkHost {
    hostName = "nix-laptop1";
    system   = "x86_64-linux";
    extraModules = [
      ./nix-laptop.nix
    ];
  };
  
  nix-laptop2 = mkHost {
    hostName = "nix-laptop2";
    system   = "x86_64-linux";
    extraModules = [
      ./nix-laptop.nix
      ../sw.nix
    ];
  };

  nix-desktop1 = mkHost {
    hostName = "nix-desktop1";
    system   = "x86_64-linux";
    extraModules = [
      ./nix-desktop.nix
      ../sw.nix
    ];
  };

  nix-surface1 = mkHost {
    hostName = "nix-surface1";
    system   = "x86_64-linux";
    extraModules = [
      ./nix-surface.nix
      ../sw-kiosk.nix
      inputs.nixos-hardware.nixosModules.microsoft-surface-go
    ];
  };
}

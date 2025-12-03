{ inputs, hostName, system ? "x86_64-linux" }:

let
  nixpkgs      = inputs.nixpkgs;
  home-manager = inputs.home-manager;
  disko        = inputs.disko;

  lib = nixpkgs.lib;

  commonModules = [
    ../boot.nix
    ../net.nix
    ../sw.nix
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
                size = "1024MiB";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  extraArgs = [ "-n" "BOOT" ];
                };
              };

              swap = {
                name = "swap";
                label = "swap";
                size = "34GiB";
                content = {
                  type = "swap";
                };
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

  # Map hostnames to their per-host module
  hostModules = {
    nix-laptop1 = ./nix-laptop1.nix;
  };
in
lib.nixosSystem {
  inherit system;

  specialArgs = { inherit inputs; };

  modules =
    commonModules
    ++ [ (hostModules.${hostName} or (throw "Unknown host '${hostName}' in hosts/default.nix")) ]
    ++ [
      { networking.hostName = hostName; }
    ];
}

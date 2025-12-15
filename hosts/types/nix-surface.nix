{ inputs, ... }:
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  refSystem = inputs.nixpkgs-old-kernel.lib.nixosSystem {
    system = pkgs.stdenv.hostPlatform.system;
    modules = [ inputs.nixos-hardware.nixosModules.microsoft-surface-go ];
  };
  refKernelPackages = refSystem.config.boot.kernelPackages;
in
{
  imports = [
    (import ../common.nix { inherit inputs; })
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.microsoft-surface-go
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    "intel_ipu3_imgu"
    "intel_ipu3_isys"
    "fbcon=map:1"
    "i915.enable_psr=0" # Panel Self Refresh breaks resume on Surface
    "i915.enable_dc=0"
  ];

  boot.kernelPackages = lib.mkForce refKernelPackages;

  ugaif.host.filesystem.swapSize = lib.mkDefault "8G";
  ugaif.host.filesystem.device = lib.mkDefault "/dev/mmcblk0";
  ugaif.host.buildMethods = lib.mkDefault [ "installer-iso" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  ugaif.sw.enable = true;
  ugaif.sw.type = lib.mkDefault "tablet-kiosk";
}

# ============================================================================
# Microsoft Surface Tablet Configuration
# ============================================================================
# Hardware configuration for Surface Go tablets in kiosk mode.
# Uses nixos-hardware module and older kernel for Surface-specific drivers.

{ inputs, ... }:
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  # Use older kernel version for better Surface Go compatibility
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

  # ========== Boot Configuration ==========

  boot.initrd.availableKernelModules = [
    "xhci_pci"    # USB 3.0 support
    "nvme"        # NVMe support (though Surface uses eMMC)
    "usb_storage" # USB storage devices
    "sd_mod"      # SD card support
    "sdhci_pci"   # SD card host controller
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # Intel virtualization support
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "quiet"                       # Minimal boot messages
    "splash"                      # Show Plymouth boot splash
    "boot.shell_on_fail"          # Emergency shell on boot failure
    "udev.log_priority=3"         # Reduce udev logging
    "rd.systemd.show_status=auto" # Show systemd status during boot
    "intel_ipu3_imgu"             # Intel camera image processing
    "intel_ipu3_isys"             # Intel camera sensor interface
    "fbcon=map:1"                 # Framebuffer console mapping
    "i915.enable_psr=0"           # Disable Panel Self Refresh (breaks resume)
    "i915.enable_dc=0"            # Disable display power saving
  ];

  # Use older kernel for better Surface hardware support
  boot.kernelPackages = lib.mkForce refKernelPackages;

  # ========== Filesystem Configuration ==========
  ugaif.host.filesystem.swapSize = lib.mkDefault "8G";
  ugaif.host.filesystem.device = lib.mkDefault "/dev/mmcblk0"; # eMMC storage # eMMC storage
  ugaif.host.buildMethods = lib.mkDefault [ "installer-iso" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # ========== Hardware Configuration ==========
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ========== Software Profile ==========
  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "tablet-kiosk"; # Touch-optimized kiosk mode
}

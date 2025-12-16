# ============================================================================
# Desktop Configuration
# ============================================================================
# Hardware and boot configuration for standard desktop workstations.
# Includes Intel CPU support and NVMe storage.

{ inputs, ... }:
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (import ../common.nix { inherit inputs; })
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ========== Boot Configuration ==========

  boot.initrd.availableKernelModules = [
    "xhci_pci"    # USB 3.0 support
    "nvme"        # NVMe SSD support
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
  ];

  # ========== Filesystem Configuration ==========
  ugaif.host.filesystem.swapSize = lib.mkDefault "16G";
  ugaif.host.filesystem.device = lib.mkDefault "/dev/nvme0n1";
  ugaif.host.buildMethods = lib.mkDefault [ "installer-iso" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # ========== Hardware Configuration ==========
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ========== Software Profile ==========
  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "desktop";
}

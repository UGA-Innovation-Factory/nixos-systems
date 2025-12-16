# ============================================================================
# Laptop Configuration
# ============================================================================
# Hardware and boot configuration for laptop systems with mobile features.
# Includes power management, lid switch handling, and Intel graphics fixes.

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
    "thunderbolt" # Thunderbolt support
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
    "i915.enable_psr=0"           # Disable Panel Self Refresh (stability)
    "i915.enable_dc=0"            # Disable display power saving
    "i915.enable_fbc=0"           # Disable framebuffer compression
  ];

  # ========== Hardware Configuration ==========
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ========== Filesystem Configuration ==========
  ugaif.host.filesystem.device = lib.mkDefault "/dev/nvme0n1";
  ugaif.host.filesystem.swapSize = lib.mkDefault "34G"; # Larger swap for hibernation
  ugaif.host.buildMethods = lib.mkDefault [ "installer-iso" ];

  # ========== Power Management ==========
  services.upower.enable = lib.mkDefault true;
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };
  };

  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "desktop";
}

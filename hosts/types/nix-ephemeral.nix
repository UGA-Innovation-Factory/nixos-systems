# ============================================================================
# Ephemeral/Diskless System Configuration
# ============================================================================
# Configuration for systems that run entirely from RAM without persistent storage.
# Suitable for kiosks, netboot clients, and stateless workstations.
# All data is lost on reboot.

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
    "xhci_pci" # USB 3.0 support
    "nvme" # NVMe support
    "usb_storage" # USB storage devices
    "sd_mod" # SD card support
    "sdhci_pci" # SD card host controller
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # Intel virtualization support
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "quiet" # Minimal boot messages
    "splash" # Show Plymouth boot splash
    "boot.shell_on_fail" # Emergency shell on boot failure
    "udev.log_priority=3" # Reduce udev logging
    "rd.systemd.show_status=auto" # Show systemd status during boot
  ];

  # ========== Ephemeral Configuration ==========
  # No persistent storage - everything runs from RAM
  ugaif.host.filesystem.swapSize = lib.mkForce "0G";
  ugaif.host.filesystem.device = lib.mkForce "/dev/null"; # Dummy device
  ugaif.host.buildMethods = lib.mkDefault [
    "iso" # Live ISO image
    "ipxe" # Network boot
  ];

  # Disable disk management for RAM-only systems
  disko.enableConfig = lib.mkForce false;

  # Define tmpfs root filesystem
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=50%"
      "mode=755"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "stateless-kiosk";
}

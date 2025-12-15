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

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
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
    "i915.enable_psr=0"
    "i915.enable_dc=0"
    "i915.enable_fbc=0"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  ugaif.host.filesystem.device = lib.mkDefault "/dev/nvme0n1";
  ugaif.host.filesystem.swapSize = lib.mkDefault "34G";
  ugaif.host.buildMethods = lib.mkDefault [ "installer-iso" ];

  # Suspend / logind behavior
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

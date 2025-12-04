{ config, pkgs, lib, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];

  disko.devices.disk.main.content.partitions.swap.size = "16G";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  environment.systemPackages = lib.subtractLists [ pkgs.zoom-us pkgs.wspoffice ] config.environment.systemPackages;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

{ inputs, ... }:
[
  (
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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
      ];

      components.host.filesystem.swapSize = lib.mkDefault "16G";
      components.host.filesystem.device = lib.mkDefault "/dev/nvme0n1";
      components.host.buildMethods = lib.mkDefault [ "installer-iso" ];
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    }
  )
  {
    components.sw.enable = true;
    components.sw.type = "desktop";
  }
]

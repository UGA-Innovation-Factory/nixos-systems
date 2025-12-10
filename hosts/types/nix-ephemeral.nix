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
      # This host type is for ephemeral, diskless systems (e.g. kiosks, netboot clients).
      # It runs entirely from RAM and does not persist state across reboots.
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

      # Ephemeral setup: No swap, no disk
      host.filesystem.swapSize = lib.mkForce "0G";
      host.filesystem.device = lib.mkForce "/dev/null"; # Dummy device
      host.buildMethods = lib.mkDefault [ "iso" "ipxe" ];
      
      # Disable Disko config since we are running from RAM/ISO
      disko.enableConfig = lib.mkForce false;

      # Define a dummy root filesystem to satisfy assertions
      fileSystems."/" = {
        device = "none";
        fsType = "tmpfs";
        options = [ "defaults" "size=50%" "mode=755" ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    }
  )
  {
    modules.sw.enable = true;
    modules.sw.type = "stateless-kiosk";
  }
]

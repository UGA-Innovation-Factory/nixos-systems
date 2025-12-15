# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

# ============================================================================
# Boot & Storage Configuration
# ============================================================================
# This module defines the Disko partition layout and bootloader settings.
# It exposes 'host.filesystem' options to allow per-host overrides of
# the target device and swap size.

{
  options.components.host = {
    filesystem = {
      device = lib.mkOption {
        type = lib.types.str;
        description = "The main disk device to use for installation.";
      };
      swapSize = lib.mkOption {
        type = lib.types.str;
        description = "The size of the swap partition.";
      };
    };
    buildMethods = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "installer-iso" ];
      description = ''
        List of allowed build methods for this host.
        Supported methods:
        - "installer-iso": Generates an auto-install ISO that installs this configuration to disk.
        - "iso": Generates a live ISO (using nixos-generators).
        - "ipxe": Generates iPXE netboot artifacts (kernel, initrd, script).
        - "lxc": Generates an LXC container tarball.
        - "proxmox": Generates a Proxmox VMA archive.
      '';
    };
  };

  config = {
    # Enable Disko for declarative partitioning
    disko.enableConfig = true;

    disko.devices = {
      disk.main = {
        type = "disk";
        device = config.components.host.filesystem.device;
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              name = "ESP";
              label = "BOOT";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
                extraArgs = [
                  "-n"
                  "BOOT"
                ];
              };
            };

            # Swap Partition (size configurable per host)
            swap = {
              name = "swap";
              label = "swap";
              size = config.components.host.filesystem.swapSize;
              content = {
                type = "swap";
              };
            };

            # Root Partition (takes remaining space)
            root = {
              name = "root";
              label = "root";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                extraArgs = [
                  "-L"
                  "ROOT"
                ];
              };
            };
          };
        };
      };
    };

    # Bootloader Configuration
    boot = {
      loader.systemd-boot.enable = lib.mkDefault true;
      loader.efi.canTouchEfiVariables = true;
      plymouth = {
        enable = true;
        theme = "ugaif";
        themePackages = [
          (pkgs.stdenvNoCC.mkDerivation {
            name = "ugaif";
            src = ../assets/plymouth-theme/ugaif;
            installPhase = ''
              sed -i 's:\(^ImageDir=\)/usr:\1'"$out"':' ugaif.plymouth
              mkdir -p $out/share/plymouth/themes/ugaif
              cp -r * $out/share/plymouth/themes/ugaif/
              cp header-image.png $out/share/plymouth/themes/ugaif/bgrt-fallback.png 
            '';
          })
        ];
      };

      # Enable "Silent boot"
      consoleLogLevel = 3;
      initrd.verbose = false;

      # Hide the OS choice for bootloaders.
      # It's still possible to open the bootloader list by pressing any key
      # It will just not appear on screen unless a key is pressed
      loader.timeout = lib.mkDefault 0;
    };

    # Set your time zone.
    time.timeZone = "America/New_York";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    systemd.sleep.extraConfig = ''
      SuspendState=freeze
      HibernateDelaySec=2h
    '';

    system.stateVersion = "25.11"; # Did you read the comment?
  };
}

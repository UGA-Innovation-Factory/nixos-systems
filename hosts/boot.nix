# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, ... }:

# ============================================================================
# Boot & Storage Configuration
# ============================================================================
# This module defines the Disko partition layout and bootloader settings.
# It exposes 'host.filesystem' options to allow per-host overrides of
# the target device and swap size.

{
  options.host = {
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
      default = [ "iso" ];
      description = "List of allowed build methods (iso, lxc, proxmox).";
    };
  };

  config = {
    # Enable Disko for declarative partitioning
    disko.enableConfig = true;

    disko.devices = {
      disk.main = {
        type = "disk";
        device = config.host.filesystem.device;
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
              size = config.host.filesystem.swapSize;
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
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
      plymouth.enable = true;

      # Enable "Silent boot"
      consoleLogLevel = 3;
      initrd.verbose = false;

      # Hide the OS choice for bootloaders.
      # It's still possible to open the bootloader list by pressing any key
      # It will just not appear on screen unless a key is pressed
      loader.timeout = 0;
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

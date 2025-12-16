# ============================================================================
# Proxmox LXC Container Configuration
# ============================================================================
# Configuration for lightweight Linux containers running in Proxmox.
# Disables boot/disk management and enables remote development support.

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
    inputs.vscode-server.nixosModules.default
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  # ========== Nix Configuration ==========
  nix.settings.trusted-users = [
    "root"
    "engr-ugaif"
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # ========== Container-Specific Configuration ==========
  boot.isContainer = true;
  boot.loader.systemd-boot.enable = lib.mkForce false; # No bootloader in container
  disko.enableConfig = lib.mkForce false; # No disk management in container
  console.enable = true;

  # Allow getty to work in containers
  systemd.services."getty@".unitConfig.ConditionPathExists = [
    ""
    "/dev/%I"
  ];

  # Suppress unnecessary systemd units for containers
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # ========== Remote Development ==========
  services.vscode-server.enable = true;

  # ========== System Configuration ==========
  system.stateVersion = "25.11";
  ugaif.host.buildMethods = lib.mkDefault [
    "lxc" # LXC container tarball
    "proxmox" # Proxmox VMA archive
  ];

  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "headless";
}

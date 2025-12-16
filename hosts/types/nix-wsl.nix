# ============================================================================
# Windows Subsystem for Linux (WSL) Configuration
# ============================================================================
# Configuration for NixOS running in WSL2 on Windows.
# Integrates with nixos-wsl for WSL-specific functionality.

{ inputs, ... }:
{
  lib,
  config,
  ...
}:
{
  imports = [
    (import ../common.nix { inherit inputs; })
    inputs.nixos-wsl.nixosModules.default
    inputs.vscode-server.nixosModules.default
  ];

  # ========== Options ==========
  options.ugaif.host.wsl.user = lib.mkOption {
    type = lib.types.str;
    default = "engr-ugaif";
    description = "The default user to log in as in WSL.";
  };

  config = {
    # ========== WSL Configuration ==========
    wsl.enable = true;
    # Use forUser if set, otherwise fall back to wsl.user option
    wsl.defaultUser =
      if config.ugaif.forUser != null then config.ugaif.forUser else config.ugaif.host.wsl.user;

    # ========== Software Profile ==========
    ugaif.sw.enable = lib.mkDefault true;
    ugaif.sw.type = lib.mkDefault "headless";

    # ========== Remote Development ==========
    services.vscode-server.enable = true;

    # ========== Disable Irrelevant Systems ==========
    # WSL doesn't use traditional boot or disk management
    disko.enableConfig = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.grub.enable = lib.mkForce false;

    # WSL manages its own networking
    systemd.network.enable = lib.mkForce false;

    # Provide dummy values for required options from boot.nix
    ugaif.host.filesystem.device = "/dev/null";
    ugaif.host.filesystem.swapSize = "0G";
  };
}

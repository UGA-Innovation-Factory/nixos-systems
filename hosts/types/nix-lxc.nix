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

  nix.settings.trusted-users = [
    "root"
    "engr-ugaif"
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.isContainer = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  disko.enableConfig = lib.mkForce false;
  console.enable = true;
  systemd.services."getty@".unitConfig.ConditionPathExists = [
    ""
    "/dev/%I"
  ];
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];
  services.vscode-server.enable = true;
  system.stateVersion = "25.11";
  ugaif.host.buildMethods = lib.mkDefault [
    "lxc"
    "proxmox"
  ];

  ugaif.sw.enable = true;
  ugaif.sw.type = lib.mkDefault "headless";
}

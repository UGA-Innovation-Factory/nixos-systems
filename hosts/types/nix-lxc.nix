{ inputs, ... }:
[
  inputs.vscode-server.nixosModules.default
  (
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      nix.settings.trusted-users = [
        "root"
        "engr-ugaif"
      ];
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      imports = [
        "${modulesPath}/virtualisation/proxmox-lxc.nix"
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
      components.host.buildMethods = lib.mkDefault [ "lxc" "proxmox" ];
    }
  )
  {
    components.sw.enable = true;
    components.sw.type = "headless";
  }
]

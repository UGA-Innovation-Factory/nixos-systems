{ inputs, ... }:
[
  inputs.nixos-wsl.nixosModules.default
  inputs.vscode-server.nixosModules.default
  ({ lib, ... }: {
    wsl.enable = true;
    wsl.defaultUser = "engr-ugaif";
    
    # Enable the headless software profile
    modules.sw.enable = true;
    modules.sw.type = "headless";

    # Fix for VS Code Server in WSL if needed, though vscode-server input exists
    services.vscode-server.enable = true;

    # Disable Disko and Bootloader for WSL
    disko.enableConfig = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.grub.enable = lib.mkForce false;

    # Disable networking for wsl (it manages its own networking)
    systemd.network.enable = lib.mkForce false;
    
    # Provide dummy values for required options from boot.nix
    host.filesystem.device = "/dev/null";
    host.filesystem.swapSize = "0G";
  })
]

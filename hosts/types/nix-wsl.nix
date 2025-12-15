{ inputs, ... }:
[
  inputs.nixos-wsl.nixosModules.default
  inputs.vscode-server.nixosModules.default
  (
    { lib, config, ... }:
    {
      options.ugaif.host.wsl.user = lib.mkOption {
        type = lib.types.str;
        default = "engr-ugaif";
        description = "The default user to log in as in WSL.";
      };

      config = {
        wsl.enable = true;
        wsl.defaultUser = config.ugaif.host.wsl.user;

        # Enable the headless software profile
        ugaif.sw.enable = true;
        ugaif.sw.type = "headless";

        # Fix for VS Code Server in WSL if needed, though vscode-server input exists
        services.vscode-server.enable = true;

        # Disable Disko and Bootloader for WSL
        disko.enableConfig = lib.mkForce false;
        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.loader.grub.enable = lib.mkForce false;

        # Disable networking for wsl (it manages its own networking)
        systemd.network.enable = lib.mkForce false;

        # Provide dummy values for required options from boot.nix
        ugaif.host.filesystem.device = "/dev/null";
        ugaif.host.filesystem.swapSize = "0G";
      };
    }
  )
]

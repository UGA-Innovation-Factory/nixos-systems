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

  options.ugaif.host.wsl.user = lib.mkOption {
    type = lib.types.str;
    default = "engr-ugaif";
    description = "The default user to log in as in WSL.";
  };

  config = {
    wsl.enable = true;
    wsl.defaultUser =
      if config.ugaif.forUser != null then config.ugaif.forUser else config.ugaif.host.wsl.user;

    # Enable the headless software profile
    ugaif.sw.enable = lib.mkDefault true;
    ugaif.sw.type = lib.mkDefault "headless";

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

{ config, lib, pkgs, inputs, hostName, hostPlatform, targetSystem, diskoScript, ... }:
{
  environment.systemPackages = [
    pkgs.git
    pkgs.bashInteractive
    pkgs.curl
    targetSystem
  ];

  # Enable networking
  networking.hostName = "autoinstaller-${hostName}";
  networking.networkmanager.enable = lib.mkForce false;
  networking.wireless = {
    enable = true;
    networks = {
      "IOT_sensors".psk = "aaaaaaaa";
    };
  };
  nixpkgs.hostPlatform = hostPlatform;

  systemd.services.auto-install = {
    description = "Automatic NixOS install for ${hostName}";
    after = [ "network-online.target" "systemd-udev-settle.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      Environment = "PATH=/run/current-system/sw/bin";
    };

    script = ''
      echo "=== AUTO INSTALL START for ${hostName} ==="

      echo ">>> Running disko script..."
      ${diskoScript}

      echo ">>> Running nixos-install..."
      nixos-install --no-root-passwd --system ${targetSystem}

      echo ">>> Done. Rebooting."
      systemctl reboot
    '';
  };
}

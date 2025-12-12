# This module configures the network for the stateless kiosk using base networking (no systemd-networkd).
{ config, lib, pkgs, inputs, ... }:
{
  networking = {
    useNetworkd = false;
    networkmanager.enable = false;
    dhcpcd.enable = true;
    useDHCP = false;
    useHostResolvConf = false;

    # Set up VLAN 5 on the primary interface (assume eth0, adjust if needed)
    vlans.vlan5 = {
      id = 5;
      interface = "eth0";
    };

    interfaces.vlan5 = {
      useDHCP = true;
    };
  };

  # Disable systemd-networkd and systemd-hostnamed
  systemd.network.enable = false;
}

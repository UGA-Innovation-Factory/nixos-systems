{ config, lib, pkgs, inputs, ... }:
{
  # Minimal container networking (systemd-networkd)
  networking = {
    useNetworkd = true;
    networkmanager.enable = false;
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    wait-online.enable = true;

    networks."10-wired" = {
      matchConfig.Type = "ether";
      networkConfig = {
        LinkLocalAddressing = false;
        DHCP = "no";
        VLAN = [ "vlan5" ];
      };
      linkConfig.RequiredForOnline = "no";
    };

    netdevs."20-vlan5" = {
      netdevConfig = {
        Kind = "vlan";
	Name = "vlan5";
      };
      vlanConfig.Id = 5;
    };

    networks."30-vlan5" = {
      matchConfig.Name = "vlan5";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}

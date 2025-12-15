{
  config,
  lib,
  pkgs,
  ...
}:

{
  ugaif.sw.python.enable = lib.mkDefault true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.printing.enable = true;

  networking.networkmanager.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    corefonts
    noto-fonts
  ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "FiraCode Nerd Font Mono" ];
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  networking.firewall.enable = true;

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];

  virtualisation.libvirtd.enable = true;

  services.thermald.enable = true;

  services.fwupd.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
}

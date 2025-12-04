{ pkgs, inputs, ... }:

{
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    tmux
    htop
    binutils
    man
    oh-my-posh
    zsh
    git
    zoom-us
    teams-for-linux
    wpsoffice
    inputs.lazyvim-nixvim.packages.${stdenv.hostPlatform.system}.nvim
  ];

  programs.zsh.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    corefonts
    noto-fonts
  ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "FiraCode Nerd Font Mono" ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Power
  services.tlp.enable = true;
  services.auto-cpufreq.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Firewall
  networking.firewall.enable = true;

  # Flatpak + portals
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-kde ];

  # Browsers
  programs.chromium.enable = true;

  # Virtualization
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Sensors
  services.hwmon.enable = true;
  services.thermald.enable = true;
  programs.sensors.enable = true;

  # Suspend / logind behavior
  services.upower.enable = true;
  services.logind.lidSwitch = "suspend";
  services.logind.extraConfig = ''
    HandleLidSwitchExternalPower=suspend
    HandleLidSwitchDocked=ignore
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}

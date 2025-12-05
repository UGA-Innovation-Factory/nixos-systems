{ pkgs, inputs, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  
  # Login manager that starts sway on a real TTY
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "engr-ugaif";
        command = ''
          /run/current-system/sw/bin/sway --config /etc/sway-kiosk.conf
        '';
      };
    };
  };

  # Sway config for kiosk
  environment.etc."sway-kiosk.conf".text = ''
    # No fancy tiling, just a fullscreen kiosk
    exec_always {
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      exec ${pkgs.chromium}/bin/chromium \
        --kiosk "https://ha.factory.uga.edu"
    }

    # On-screen keyboard (once you add wvkbd)
    exec_always ${pkgs.wvkbd}/bin/wvkbd-mobintl

    # Basic output config if needed
    output * scale 1
  '';

  services.dbus.enable = true;
  services.dbus.implementation = "dbus";

  services.cage = {
    enable = false;
    user = "engr-ugaif";
    program = "${(pkgs.writeShellScriptBin "chromium-kiosk" ''
      sleep 5
      ${pkgs.chromium}/bin/chromium --kiosk "https://ha.factory.uga.edu"
    '')}/bin/chromium-kiosk";
  };

  # Enable networking
  networking.networkmanager.enable = false;
  networking.wireless = {
    enable = true;
    networks = {
      "IOT_vr" = {
        ssid = "IOT_vr";
        pskRaw = "849a13f095b73a3d038a904576fd8ad4b83da81d285acaf435b545c1560c7e27";
	authProtocols = [ "WPA-PSK" ];
      };
      "IOT_sensors".psk = "aaaaaaaa";
    };
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    htop
    binutils
    (chromium.override {
      commandLineArgs = [ "--enable-features=TouchpadOverscrollHistoryNavigation" ];
    })
    oh-my-posh
    zsh
    git
    squeekboard
    dbus
    inputs.lazyvim-nixvim.packages.${stdenv.hostPlatform.system}.nvim
  ];

  programs.chromium = {
    enable = true;
    extensions = [
      # "ofelldpjbfeheadojfhkagakafgghlji" # Chrome Virtual Keyboard
    ];
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
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

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Firewall
  networking.firewall.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}

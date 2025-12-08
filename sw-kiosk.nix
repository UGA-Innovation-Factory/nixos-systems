{ pkgs, inputs, ... }:

{
  services.xserver = {
    enable = true;
    desktopManager.phosh = {
      enable = true;
      user = "engr-ugaif";
      group = "users";
    };
  };

  services.displayManager = {
    gdm.enable = true;
    autoLogin = {
      enable = true;
      user = "engr-ugaif";
    };
  };

  services.dbus.enable = true;

  programs.dconf = {
    enable = true;
    profiles.user = {
      databases = [{
	settings = {
	  "org/gnome/desktop/interface" = {
	    color-scheme = "prefer-dark";
	    clock-format = "12h";
	    clock-show-weekday = true;
	  };
	  "org/gnome/desktop/media-handling" = {
	    automount = false;
	    automount-open = false;
	    autorun-never = true;
	  };
	  "org/gnome/settings-daemon/plugins/power" = {
	    sleep-inactive-ac-type = "nothing";
	  };
	  "org/gnome/desktop/a11y/applications" = {
            screen-keyboard-enabled = true;
	  };
	};
      }];
    };
  };

  i18n.inputMethod = {
    type = "ibus";
    enable = true;
    ibus.engines = [ pkgs.ibus-engines.m17n ];
  };
  
  services.gnome.gnome-keyring.enable = inputs.nixpkgs.lib.mkForce false;

  systemd.user.services.squeekboard = {
    description = "Squeekboard on-screen keyboard";
    wantedBy = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.squeekboard}/bin/squeekboard";
      Restart = "on-failure";
    };
  };

  environment.sessionVariables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";

    # Make GLib / gsettings actually see schemas
    XDG_DATA_DIRS = [ "/run/current-system/sw/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" ];
    GSETTINGS_SCHEMA_DIR =
      "/run/current-system/sw/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  };

  systemd.user.services."force-osk" = {
    description = "Force the OSK to Enable";
    wantedBy = [ "chromium-kiosk.service" ];
    partOf   = [ "chromium-kiosk.service" ];

    serviceConfig = {
      ExecStart = ''
        /bin/bash -c ' \
	  /run/current-system/sw/bin/sleep 5; \
	  /run/current-system/sw/bin/dconf reset /org/gnome/desktop/a11y/applications/screen-keyboard-enabled
	'
      '';
      Type = "exec";
    };
  };

  systemd.user.services."chromium-kiosk" = {
    description = "Chromium kiosk";
    wantedBy = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.chromium}/bin/chromium \
          --enable-features=UseOzonePlatform,TouchpadOverscrollHistoryNavigation \
          --ozone-platform=wayland \
          --kiosk \
          --start-fullscreen \
          --noerrdialogs \
          --disable-session-crashed-bubble \
          --disable-infobars \
          https://ha.factory.uga.edu
      '';
    };
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
    wireplumber.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    htop
    binutils
    libcamera
    chromium
    oh-my-posh
    zsh
    git
    glib
    squeekboard
    dconf
    phoc
    gsettings-desktop-schemas
    inputs.lazyvim-nixvim.packages.${stdenv.hostPlatform.system}.nvim
  ];

  programs.chromium = {
    enable = true;
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

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Firewall
  networking.firewall.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}

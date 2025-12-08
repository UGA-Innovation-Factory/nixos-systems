{ pkgs, inputs, ... }:

{
  services.cage = {
    enable = false;
    user = "engr-ugaif";
    program = "${(pkgs.writeShellScriptBin "chromium-kiosk" ''
      sleep 5
      ${pkgs.chromium}/bin/chromium --kiosk "https://ha.factory.uga.edu"
    '')}/bin/chromium-kiosk";
  };

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
  
  security.pam.services."login".enableGnomeKeyring = true;
  security.pam.services."gdm-password".enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

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

  services.xserver.libinput = {
    enable = true;
    devices = {
      "disable-ghost-keyboard" = {
	matchDevice = "AT Translated Set 2 keyboard";
	ignore = true;
      };
    };
  };

  services.udev.extraRules = ''
    # These shouldn't be counted as keyboards, but should still produce events
    ACTION=="add|change", KERNEL=="event*", ATTRS{name}=="Video Bus", \
      ENV{ID_INPUT_KEYBOARD}="", ENV{ID_INPUT_KEY}=""
    ACTION=="add|change", KERNEL=="event*", ATTRS{name}=="Power Button", \
      ENV{ID_INPUT_KEYBOARD}="", ENV{ID_INPUT_KEY}=""
    ACTION=="add|change", KERNEL=="event*", ATTRS{name}=="Intel HID events", \
      ENV{ID_INPUT_KEYBOARD}="", ENV{ID_INPUT_KEY}=""
    ACTION=="add|change", KERNEL=="event*", ATTRS{name}=="Intel HID 5 button array", \
      ENV{ID_INPUT_KEYBOARD}="", ENV{ID_INPUT_KEY}=""
    ACTION=="change", SUBSYSTEM=="switch", ATTRS{name}=="Intel HID switches", \
      ENV{SW_TABLET_MODE}="1"
  '';

  systemd.user.services."force-osk" = {
    description = "Force-enable GNOME OSK after session init";
    wantedBy = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];

    unitConfig = {
      After = [ "gnome-session-initialized.target" "graphical-session.target" ];
    };

    serviceConfig = {
      ExecStart = ''
	${pkgs.glib.bin}/bin/gsettings set \
	  org.gnome.desktop.a11y.applications screen-keyboard-enabled true
      '';
      Type = "oneshot";
    };
  };

  systemd.user.services."chromium-kiosk" = {
    description = "Chromium kiosk";
    wantedBy = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.chromium}/bin/chromium \
          --enable-features=UseOzonePlatform \
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
    glib
    squeekboard
    dconf
    phoc
    gsettings-desktop-schemas
    #(pkgs.writeShellScriptBin "osk-wayland" ''
    #  exec ${pkgs.squeekboard}/bin/squeekboard "$@"
    #'')
    inputs.lazyvim-nixvim.packages.${stdenv.hostPlatform.system}.nvim
  ];

  programs.chromium = {
    enable = true;
    extensions = [
      # "ecjkcanpimnagobhegghdeeiagffoidk" # Chrome Virtual Keyboard
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

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Firewall
  networking.firewall.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}

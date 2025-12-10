{ config, lib, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    desktopManager.phosh = {
      enable = true;
      user = "engr-ugaif";
      group = "users";
    };
  };

  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "engr-ugaif";
  };

  services.dbus.enable = true;

  services.fwupd.enable = true;

  i18n.inputMethod = {
    type = "ibus";
    enable = true;
    ibus.engines = [ pkgs.ibus-engines.m17n ];
  };
  
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  environment.sessionVariables = {
    GDK_SCALE = "1.25";
    GDK_DPI_SCALE = "0.5";

    # Make GLib / gsettings actually see schemas
    XDG_DATA_DIRS = [ "/run/current-system/sw/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" ];
    GSETTINGS_SCHEMA_DIR =
      "/run/current-system/sw/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  };

  environment.etc."machine-info".text = ''
    CHASSIS=handset
  '';

  services.logind.settings.Login = {
    HandlePowerKey="ignore";
    HandleSuspendKey="ignore";
    HandleHibernateKey="ignore";
    HandleLidSwitch="ignore";
    HandleLidSwitchExternalPower="ignore";
    IdleAction="ignore";
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

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "FiraCode Nerd Font Mono" ];
  };

  systemd.user.services.squeekboard = {
    description = "Squeekboard on-screen keyboard";
    wantedBy = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.squeekboard}/bin/squeekboard";
      Restart = "on-failure";
    };
  };

  systemd.user.services."force-osk" = {
    description = "Force the OSK to Enable";
    wantedBy = [ "chromium-kiosk.service" ];
    partOf   = [ "chromium-kiosk.service" ];

    serviceConfig = {
      ExecStartPre = ''
        /run/current-system/sw/bin/sleep 5 
      '';
      ExecStart = ''
        /run/current-system/sw/bin/dconf reset /org/gnome/desktop/a11y/applications/screen-keyboard-enabled
      '';
      Type = "simple";
    };
  };

  systemd.user.services."force-input-sources" = {
    description = "Force the Gsettings Input Sources";
    wantedBy = [ "chromium-kiosk.service" ];
    partOf   = [ "chromium-kiosk.service" ];

    serviceConfig = {
      ExecStartPre = ''
        /run/current-system/sw/bin/sleep 5 
      '';
      ExecStart = ''
        /run/current-system/sw/bin/dconf reset /org/gnome/desktop/input-sources/sources
      '';
      ExecStartPost = ''
        /run/current-system/sw/bin/dconf reset /org/gnome/desktop/mru-sources/sources
      '';

      Type = "simple";
    };
  };

  systemd.user.services."chromium-kiosk" = {
    description = "Chromium kiosk";
    wantedBy = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.chromium}/bin/chromium \
          --enable-features=UseOzonePlatform,TouchpadOverscrollHistoryNavigation,PullToRefresh \
          --ozone-platform=wayland \
          --kiosk \
          --start-fullscreen \
          --noerrdialogs \
          --disable-session-crashed-bubble \
          --disable-infobars \
          ${config.modules.sw.kioskUrl}
      '';
    };
  };
}

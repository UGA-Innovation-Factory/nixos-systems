{ config, lib, inputs, ... }:

let
  cfg = config.modules.sw;
in {
  config = lib.mkIf (cfg.enable && cfg.type == "kiosk") {
    programs.dconf = {
      enable = true;
      profiles.user = {
        databases = [{
          settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              clock-format = "12h";
              clock-show-weekday = true;
              show-battery-percentage = true;
            };
            "org/gnome/desktop/media-handling" = {
              automount = false;
              automount-open = false;
              autorun-never = true;
            };
            "org/gnome/settings-daemon/plugins/power" = {
              sleep-inactive-ac-type = "nothing";
            };
            "org/gnome/desktop/lockdown" = {
              disable-lock-screen = true;
            };
            "org/gnome/desktop/screensaver" = {
              lock-enabled = false;
            };
            "org/gnome/desktop/session" = {
              idle-delay = inputs.nixpkgs.lib.gvariant.mkUint32 0;
            };
            "org/gnome/desktop/input-sources" = {
              sources = "[('ibus', 'xkb:us::eng')]";
            };
            "org/gnome/desktop/mru-sources" = {
              sources = "[('ibus', 'xkb:us::eng')]";
            };
            "sm/puri/phosh" = {
              lock-enabled = false;
            };
            "org/gnome/desktop/a11y/applications" = {
              screen-keyboard-enabled = true;
            };
          };
        }];
      };
    };
  };
}

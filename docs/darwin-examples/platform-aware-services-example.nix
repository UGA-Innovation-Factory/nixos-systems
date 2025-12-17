# Example Platform-Aware Service Configuration
# This shows how sw/desktop/services.nix would be modified
# File location: sw/desktop/services.nix

{ config, lib, pkgs, ... }:
lib.mkMerge [
  # ========== Linux-Specific Services ==========
  (lib.mkIf pkgs.stdenv.isLinux {
    # Python development tools
    ugaif.sw.python.enable = lib.mkDefault true;

    # Display manager and desktop environment
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    # Printing
    services.printing.enable = true;

    # Network management
    networking.networkmanager.enable = true;

    # Audio (PipeWire)
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Bluetooth
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # Firewall
    networking.firewall.enable = true;

    # Flatpak
    services.flatpak.enable = true;
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];

    # Virtualization
    virtualisation.libvirtd.enable = true;

    # Hardware monitoring
    services.thermald.enable = true;
    services.fwupd.enable = true;

    # SSH
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };

    # System updater (systemd timer)
    systemd.timers.system-updater = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
    systemd.services.system-updater = {
      description = "Update system configuration";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl start nixos-rebuild";
      };
    };
  })

  # ========== Darwin-Specific Services ==========
  (lib.mkIf pkgs.stdenv.isDarwin {
    # Python development tools (works on both platforms)
    ugaif.sw.python.enable = lib.mkDefault true;

    # No display manager needed (macOS native)
    # No desktop environment (macOS Aqua)
    
    # Printing is built into macOS, just needs to be enabled if needed
    # Most GUI services use native macOS implementations

    # SSH (similar to Linux but uses launchd)
    services.nix-daemon.enable = true;
    
    # System updater (launchd agent instead of systemd timer)
    launchd.agents.system-updater = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "darwin-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems"
        ];
        StartCalendarInterval = [
          { Hour = 3; Minute = 0; }  # Daily at 3 AM
        ];
        StandardOutPath = "/var/log/system-updater.log";
        StandardErrorPath = "/var/log/system-updater.err";
      };
    };

    # Homebrew integration (optional, for Mac-only apps)
    # homebrew = {
    #   enable = true;
    #   casks = [
    #     # Mac-only applications that aren't in nixpkgs
    #   ];
    # };
  })

  # ========== Cross-Platform Services ==========
  {
    # Fonts (work on both platforms)
    fonts.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
      noto-fonts
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      corefonts  # Microsoft fonts (Linux only due to licensing)
    ];
    
    fonts.fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "FiraCode Nerd Font Mono" ];
    };
  }
]

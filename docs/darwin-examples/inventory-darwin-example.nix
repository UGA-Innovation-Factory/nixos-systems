# Example Inventory with Darwin Hosts
# This shows how inventory.nix would look with both Linux and Darwin systems
# File location: inventory.nix

{
  # ========== Linux Systems (Existing) ==========
  
  nix-laptop = {
    devices = 2;
    overrides.extraUsers = [ "hdh20267" ];
  };

  nix-desktop = {
    devices = 1;
  };

  nix-surface = {
    defaultCount = 3;
    devices = {
      "1".ugaif.sw.kioskUrl = "https://google.com";
    };
    overrides = {
      ugaif.sw.kioskUrl = "https://yahoo.com";
    };
  };

  nix-lxc = {
    devices = {
      "nix-builder" = { };
      "usda-dash" = builtins.fetchGit {
        url = "https://git.factory.uga.edu/MODEL/usda-dash-config.git";
        rev = "c47ab8fe295ba38cf3baa8670812b23a09fb4d53";
      };
    };
    overrides = {
      ugaif.host.useHostPrefix = false;
    };
  };

  nix-wsl = {
    devices = {
      "alireza".ugaif.forUser = "sv22900";
    };
  };

  nix-ephemeral.devices = 1;

  # ========== Darwin Systems (New) ==========

  # MacBook Pro laptops for developers
  darwin-laptop = {
    type = "darwin-laptop";
    system = "aarch64-darwin";  # Apple Silicon
    devices = 3;
    overrides = {
      extraUsers = [ "developer1" "developer2" ];
    };
  };

  # Intel-based MacBook Air
  darwin-laptop-intel = {
    type = "darwin-laptop";
    system = "x86_64-darwin";  # Intel Mac
    devices = {
      "legacy1" = {
        extraUsers = [ "researcher" ];
      };
    };
  };

  # iMac and Mac Mini workstations
  darwin-desktop = {
    type = "darwin-desktop";
    system = "aarch64-darwin";
    devices = {
      "studio1" = {
        extraUsers = [ "designer" ];
        ugaif.sw.extraPackages = with pkgs; [
          # Design tools
        ];
      };
      "mini1" = {
        extraUsers = [ "admin" ];
      };
    };
  };

  # Mac Studio for high-performance work (optional)
  darwin-studio = {
    type = "darwin-studio";
    system = "aarch64-darwin";
    devices = {
      "render1" = {
        extraUsers = [ "render-user" ];
        # High-performance configuration
      };
    };
  };

  # Example: Developer's personal MacBook
  darwin-laptop-personal = {
    type = "darwin-laptop";
    system = "aarch64-darwin";
    devices = {
      "alice".ugaif.forUser = "alice-dev";
      "bob".ugaif.forUser = "bob-eng";
    };
  };

  # Example: Darwin system with external module
  darwin-external = {
    type = "darwin-desktop";
    system = "aarch64-darwin";
    devices = {
      "custom-mac" = builtins.fetchGit {
        url = "https://github.com/example/mac-config";
        rev = "abc123def456...";
      };
    };
  };
}

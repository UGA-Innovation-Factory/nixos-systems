{
  # ============================================================================
  # Fleet Inventory
  # ============================================================================
  # This file defines the types of hosts and their counts. It is used by
  # hosts/default.nix to generate the full set of NixOS configurations.
  #
  # Structure:
  #   <host-type> = {
  #     count = <number>;       # Number of hosts to generate (e.g., nix-laptop1, nix-laptop2)
  #     devices = {             # Per-device overrides
  #       "<index>" = {
  #         extraUsers = [ ... ];  # Users enabled on this specific device
  #         flakeUrl = "...";      # Optional external system flake for full override
  #         ...                    # Other hardware/filesystem overrides
  #       };
  #     };
  #   };

  # Laptop Configuration
  # Base specs: NVMe drive, 34G Swap
  nix-laptop = {
    count = 2;
    devices = {
      # Override example:
      # "2" = { swapSize = "64G"; };

      # Enable specific users for this device index
      "1" = {
        extraUsers = [ "hdh20267" ];
      };
      "2" = {
        extraUsers = [ "hdh20267" ];
      };

      # Example of using an external flake for system configuration:
      # "2" = { flakeUrl = "github:user/system-flake"; };
    };
  };

  # Desktop Configuration
  # Base specs: NVMe drive, 16G Swap
  nix-desktop.count = 1;

  # Surface Tablet Configuration (Kiosk Mode)
  # Base specs: eMMC drive, 8G Swap
  nix-surface = {
    count = 3;
    devices = {
      "1".modules.sw.kioskUrl = "https://google.com";
    };
  };

  # LXC Container Configuration
  nix-lxc = {
    count = 1;
    devices = {
      "1" = {
        hostname = "nix-builder";
      };
    };
  };

  # WSL Configuration
  nix-wsl = {
    count = 1;
    devices = {
      "1" = {
        hostname = "nix-wsl-alireza";
        extraUsers = [ "sv22900" ];
        wslUser = "sv22900";
      };
    };
  };

  # Ephemeral Configuration (Live ISO / Netboot)
  nix-ephemeral.count = 1;
}

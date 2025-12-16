{
  # ============================================================================
  # Fleet Inventory
  # ============================================================================
  # Top-level keys are ALWAYS hostname prefixes. Actual hostnames are generated
  # from the devices map or count.
  #
  # Hostname generation rules:
  # - Numeric suffixes: no dash (e.g., "nix-surface1", "nix-surface2")
  # - Non-numeric suffixes: add dash (e.g., "nix-surface-alpha", "nix-surface-beta")
  # - Set ugaif.host.useHostPrefix = false to use suffix as full hostname
  #
  # Format:
  #   "prefix" = {
  #     type = "nix-desktop";        # Optional: defaults to prefix name
  #     system = "x86_64-linux";     # Optional: default is x86_64-linux
  #
  #     # Option 1: Simple count (quick syntax)
  #     devices = 5;                 # Creates: prefix1, prefix2, ..., prefix5
  #
  #     # Option 2: Explicit count
  #     count = 5;                   # Creates: prefix1, prefix2, ..., prefix5
  #
  #     # Option 3: Default count (for groups with mixed devices)
  #     defaultCount = 3;            # Creates default numbered hosts
  #
  #     # Option 4: Named device configurations
  #     devices = {
  #       "1" = { ... };             # Creates: prefix1
  #       "alpha" = { ... };         # Creates: prefix-alpha
  #       "custom" = {               # Creates: custom (no prefix)
  #         ugaif.host.useHostPrefix = false;
  #       };
  #     };
  #
  #     # Common config for all devices in this group
  #     overrides = {
  #       extraUsers = [ "user1" ];  # Applied to all devices in this group
  #       # ... any other config
  #     };
  #   };
  #
  # Convenience options:
  #   ugaif.forUser = "username";  # Automatically adds user to extraUsers and sets wslUser for WSL
  #
  # Examples:
  #   "lab" = { devices = 3; };                           # Quick: lab1, lab2, lab3
  #   "lab" = { count = 3; };                             # Same as above
  #   "kiosk" = {
  #     defaultCount = 2;                                 # kiosk1, kiosk2 (default)
  #     devices."special" = {};                           # kiosk-special (custom)
  #   };
  #   "laptop" = {
  #     devices = 5;
  #     overrides.extraUsers = [ "student" ];             # All 5 laptops get this user
  #   };
  #   "wsl" = {
  #     devices."alice".ugaif.forUser = "alice123";       # Sets up for user alice123
  #   };  # ========== Lab Laptops ==========
  # Creates: nix-laptop1, nix-laptop2
  # Both get hdh20267 user via overrides
  nix-laptop = {
    devices = 2;
    overrides.extraUsers = [ "hdh20267" ];
  };

  # ========== Desktop ==========
  # Creates: nix-desktop1
  nix-desktop = {
    devices = 1;
  };

  # ========== Surface Tablets (Kiosk Mode) ==========
  # Creates: nix-surface1 (custom), nix-surface2, nix-surface3 (via defaultCount)
  nix-surface = {
    defaultCount = 3;
    devices = {
      "1".ugaif.sw.kioskUrl = "https://google.com";
    };
    overrides = {
      ugaif.sw.kioskUrl = "https://yahoo.com";
    };
  };

  # ========== LXC Containers ==========
  # Creates: nix-builder (without lxc prefix)
  nix-lxc = {
    devices = {
      "nix-builder" = { };
      "usda-dash" = { };
    };
    overrides = {
      ugaif.host.useHostPrefix = false;
    };
  };

  # ========== WSL Instances ==========
  # Creates: nix-wsl-alireza
  nix-wsl = {
    devices = {
      "alireza".ugaif.forUser = "sv22900";
    };
  };

  # ========== Ephemeral/Netboot System ==========
  # Creates: nix-ephemeral1
  nix-ephemeral.devices = 1;
}

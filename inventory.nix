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
  #       ugaif.users.user1.enable = true;  # Applied to all devices in this group
  #       # ... any other config
  #     };
  #   };
  #
  # Convenience options:
  #   ugaif.forUser = "username";  # Automatically enables user (sets ugaif.users.username.enable = true)
  #
  # External modules (instead of config):
  #   Device values can be either a config attrset OR a fetchGit/fetchurl call
  #   that points to an external Nix module. The module will be imported and evaluated.
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
  #     overrides.ugaif.users.student.enable = true;     # All 5 laptops get this user
  #   };
  #   "wsl" = {
  #     devices."alice".ugaif.forUser = "alice123";       # Sets up for user alice123
  #   };
  #   "external" = {
  #     devices."remote" = builtins.fetchGit {            # External module via Git
  #       url = "https://github.com/example/config";
  #       rev = "abc123...";
  #     };
  #   };  # ========== Lab Laptops ==========
  # Creates: nix-laptop1, nix-laptop2
  # Both get hdh20267 user via overrides
  nix-laptop = {
    devices = 2;
    overrides.ugaif.users.hdh20267.enable = true;
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
      "usda-dash" = builtins.fetchGit {
        url = "https://git.factory.uga.edu/MODEL/usda-dash-config.git";
        rev = "c47ab8fe295ba38cf3baa8670812b23a09fb4d53";
      };
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

  # ========== Example: External Module Configurations ==========
  # Uncomment to use external modules from Git repositories:
  #
  # external-systems = {
  #   devices = {
  #     # Option 1: fetchGit with specific revision (recommended for reproducibility)
  #     "prod-server" = builtins.fetchGit {
  #       url = "https://github.com/example/server-config";
  #       rev = "abc123def456...";  # Full commit hash
  #       ref = "main";              # Optional: branch/tag name
  #     };
  #
  #     # Option 2: fetchGit with latest from branch (less reproducible)
  #     "dev-server" = builtins.fetchGit {
  #       url = "https://github.com/example/server-config";
  #       ref = "develop";
  #     };
  #
  #     # Option 3: fetchTarball for specific release
  #     "test-server" = builtins.fetchTarball {
  #       url = "https://github.com/example/server-config/archive/v1.0.0.tar.gz";
  #       sha256 = "sha256:0000000000000000000000000000000000000000000000000000";
  #     };
  #
  #     # Option 4: Mix external module with local overrides
  #     # Note: The external module's default.nix should export a NixOS module
  #     # that accepts { inputs, ... } as parameters
  #   };
  # };
}

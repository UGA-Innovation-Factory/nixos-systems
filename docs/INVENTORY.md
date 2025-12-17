# Host Inventory Configuration

This guide explains how to configure hosts in `inventory.nix` to define your fleet of devices.

## Table of Contents

- [Understanding Inventory Structure](#understanding-inventory-structure)
- [Hostname Generation Rules](#hostname-generation-rules)
- [Adding Hosts](#adding-hosts)
- [Device Configuration Options](#device-configuration-options)
- [Examples](#examples)

## Understanding Inventory Structure

The `inventory.nix` file defines all hosts in the fleet using a flexible system. Top-level keys are always hostname **prefixes**, and actual hostnames are generated from device configurations.

## Hostname Generation Rules

- **Numeric suffixes**: no dash (e.g., `nix-laptop1`, `nix-laptop2`)
- **Non-numeric suffixes**: with dash (e.g., `nix-laptop-alpha`, `nix-laptop-beta`)  
- **Custom hostnames**: Set `ugaif.host.useHostPrefix = false` to use suffix as full hostname

## Adding Hosts

### Method 1: Quick Count (Simplest)

```nix
nix-laptop = {
  devices = 5;  # Creates: nix-laptop1, nix-laptop2, ..., nix-laptop5
};
```

### Method 2: Explicit Count with Overrides

```nix
nix-laptop = {
  devices = 5;
  overrides = {
    # Applied to ALL nix-laptop hosts
    ugaif.users.student.enable = true;
    ugaif.sw.extraPackages = with pkgs; [ vim git ];
  };
};
```

### Method 3: Individual Device Configuration

```nix
nix-surface = {
  devices = {
    "1".ugaif.sw.kioskUrl = "https://dashboard1.example.com";
    "2".ugaif.sw.kioskUrl = "https://dashboard2.example.com";
    "3".ugaif.sw.kioskUrl = "https://dashboard3.example.com";
  };
};
```

### Method 4: Mixed (Default Count + Custom Devices)

```nix
nix-surface = {
  defaultCount = 2;  # Creates nix-surface1, nix-surface2
  devices = {
    "special" = {  # Creates nix-surface-special
      ugaif.sw.kioskUrl = "https://special-dashboard.example.com";
    };
  };
  overrides = {
    # Applied to all devices (including "special")
    ugaif.sw.kioskUrl = "https://default-dashboard.example.com";
  };
};
```

## Device Configuration Options

### Direct Configuration (Recommended)

Use any NixOS or `ugaif.*` option:

```nix
"1" = {
  # UGAIF options
  ugaif.users.myuser.enable = true;
  ugaif.host.filesystem.swapSize = "64G";
  ugaif.sw.extraPackages = with pkgs; [ docker ];
  ugaif.sw.kioskUrl = "https://example.com";
  
  # Standard NixOS options
  networking.firewall.enable = false;
  services.openssh.enable = true;
  time.timeZone = "America/New_York";
};
```

### Convenience: `ugaif.forUser`

Quick setup for single-user systems (especially WSL):

```nix
nix-wsl = {
  devices = {
    "alice".ugaif.forUser = "alice-username";
  };
};
```

This automatically enables the user account.

### External System Configuration

For complex configurations, use external modules (see [EXTERNAL_MODULES.md](../EXTERNAL_MODULES.md)):

```nix
nix-lxc = {
  devices = {
    "special-server" = builtins.fetchGit {
      url = "https://github.com/org/server-config";
      rev = "abc123...";
    };
  };
};
```

## Examples

### Simple Lab Computers

```nix
nix-laptop = {
  devices = 10;  # Creates nix-laptop1 through nix-laptop10
  overrides = {
    ugaif.users.student.enable = true;
  };
};
```

### Mixed Surface Tablets

```nix
nix-surface = {
  defaultCount = 5;  # nix-surface1 through nix-surface5 (default config)
  devices = {
    "admin" = {  # nix-surface-admin (special config)
      ugaif.sw.type = "desktop";  # Full desktop instead of kiosk
      ugaif.users.admin.enable = true;
    };
  };
  overrides = {
    ugaif.sw.type = "tablet-kiosk";
    ugaif.sw.kioskUrl = "https://dashboard.factory.uga.edu";
  };
};
```

### LXC Containers

```nix
nix-lxc = {
  devices = {
    "nix-builder" = {
      ugaif.sw.type = "headless";
    };
    "webserver" = {
      ugaif.sw.type = "headless";
      services.nginx.enable = true;
    };
  };
  overrides = {
    ugaif.host.useHostPrefix = false;  # Use exact device key as hostname
  };
};
```

### WSL Instances

```nix
nix-wsl = {
  devices = {
    "alice".ugaif.forUser = "alice-uga";
    "bob".ugaif.forUser = "bob-uga";
  };
};
```

## See Also

- [USER_CONFIGURATION.md](USER_CONFIGURATION.md) - User account management
- [EXTERNAL_MODULES.md](EXTERNAL_MODULES.md) - External configuration modules
- [Configuration Namespace Reference](NAMESPACE.md) - All `ugaif.*` options

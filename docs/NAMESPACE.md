# Configuration Namespace Reference

All UGA Innovation Factory-specific options are under the `ugaif` namespace to avoid conflicts with standard NixOS options.

## Table of Contents

- [Host Configuration (`ugaif.host`)](#host-configuration-ugaifhost)
- [Software Configuration (`ugaif.sw`)](#software-configuration-ugaifsw)
- [User Management (`ugaif.users`)](#user-management-ugaifusers)
- [System Configuration (`ugaif.system`)](#system-configuration-ugaifsystem)
- [Convenience Options](#convenience-options)

## Host Configuration (`ugaif.host`)

Hardware and host-specific settings.

### `ugaif.host.filesystem`

Disk and storage configuration.

**Options:**
- `ugaif.host.filesystem.device` - Boot disk device (default: `/dev/sda`)
- `ugaif.host.filesystem.swapSize` - Swap file size (default: `"32G"`)

**Example:**
```nix
ugaif.host.filesystem = {
  device = "/dev/nvme0n1";
  swapSize = "64G";
};
```

### `ugaif.host.buildMethods`

List of supported build artifact types for this host.

**Type:** List of strings

**Options:** `"installer-iso"`, `"iso"`, `"ipxe"`, `"lxc"`, `"proxmox"`

**Default:** `["installer-iso"]`

**Example:**
```nix
ugaif.host.buildMethods = [ "lxc" "proxmox" ];
```

### `ugaif.host.useHostPrefix`

Whether to prepend the host type prefix to the hostname (used in inventory generation).

**Type:** Boolean

**Default:** `true`

**Example:**
```nix
ugaif.host.useHostPrefix = false;  # "builder" instead of "nix-lxc-builder"
```

### `ugaif.host.wsl`

WSL-specific configuration options.

**Options:**
- `ugaif.host.wsl.user` - Default WSL user for this instance

**Example:**
```nix
ugaif.host.wsl.user = "myusername";
```

## Software Configuration (`ugaif.sw`)

System software and application configuration.

### `ugaif.sw.enable`

Enable the software configuration module.

**Type:** Boolean

**Default:** `true`

### `ugaif.sw.type`

System type that determines the software profile.

**Type:** Enum

**Options:**
- `"desktop"` - Full desktop environment (GNOME)
- `"tablet-kiosk"` - Surface tablets with kiosk mode browser
- `"stateless-kiosk"` - Diskless PXE boot kiosks
- `"headless"` - Servers and containers without GUI

**Default:** `"desktop"`

**Example:**
```nix
ugaif.sw.type = "headless";
```

### `ugaif.sw.kioskUrl`

URL to display in kiosk mode browsers (for `tablet-kiosk` and `stateless-kiosk` types).

**Type:** String

**Default:** `"https://ha.factory.uga.edu"`

**Example:**
```nix
ugaif.sw.kioskUrl = "https://dashboard.example.com";
```

### `ugaif.sw.python`

Python development tools configuration.

**Options:**
- `ugaif.sw.python.enable` - Enable Python tools (pixi, uv) (default: `true`)

**Example:**
```nix
ugaif.sw.python.enable = true;
```

### `ugaif.sw.remoteBuild`

Remote build server configuration for offloading builds.

**Options:**
- `ugaif.sw.remoteBuild.enable` - Use remote builders (default: enabled on tablets)
- `ugaif.sw.remoteBuild.hosts` - List of build server hostnames

**Example:**
```nix
ugaif.sw.remoteBuild = {
  enable = true;
  hosts = [ "nix-builder" "nix-builder2" ];
};
```

### `ugaif.sw.extraPackages`

Additional system packages to install beyond the type defaults.

**Type:** List of packages

**Default:** `[]`

**Example:**
```nix
ugaif.sw.extraPackages = with pkgs; [
  vim
  htop
  docker
];
```

### `ugaif.sw.excludePackages`

Packages to exclude from the default list for this system type.

**Type:** List of packages

**Default:** `[]`

**Example:**
```nix
ugaif.sw.excludePackages = with pkgs; [
  firefox  # Remove Firefox from default desktop packages
];
```

## User Management (`ugaif.users`)

User account configuration and management.

### `ugaif.users.<username>.enable`

Enable a specific user account on this system.

**Type:** Boolean

**Default:** `false` (except `root` and `engr-ugaif` which default to `true`)

**Example:**
```nix
ugaif.users = {
  myuser.enable = true;
  student.enable = true;
};
```

### User Account Options

Each user in `users.nix` can be configured with:

```nix
ugaif.users.myuser = {
  description = "Full Name";
  isNormalUser = true;                    # Default: true
  extraGroups = [ "wheel" "docker" ];     # Additional groups
  shell = pkgs.zsh;                       # Login shell
  hashedPassword = "$6$...";              # Hashed password
  opensshKeys = [ "ssh-ed25519 ..." ];    # SSH public keys
  homePackages = with pkgs; [ ... ];      # User packages
  useZshTheme = true;                     # Use system Zsh theme
  useNvimPlugins = true;                  # Use system Neovim config
  
  # External home-manager configuration (optional)
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";
  };
  
  enable = false;  # Enable per-system in inventory.nix
};
```

## System Configuration (`ugaif.system`)

System-wide settings and services.

### `ugaif.system.gc`

Automatic garbage collection configuration.

**Options:**
- `ugaif.system.gc.enable` - Enable automatic garbage collection (default: `true`)
- `ugaif.system.gc.frequency` - How often to run (default: `"weekly"`)
- `ugaif.system.gc.retentionDays` - Days to keep old generations (default: `30`)
- `ugaif.system.gc.optimise` - Optimize Nix store automatically (default: `true`)

**Example:**
```nix
ugaif.system.gc = {
  enable = true;
  frequency = "daily";
  retentionDays = 14;
  optimise = true;
};
```

## Convenience Options

### `ugaif.forUser`

Quick setup option that enables a user account in one line.

**Type:** String (username) or null

**Default:** `null`

**Example:**
```nix
ugaif.forUser = "myusername";  # Equivalent to ugaif.users.myusername.enable = true
```

**Usage in inventory.nix:**
```nix
nix-wsl = {
  devices = {
    "alice".ugaif.forUser = "alice-uga";
  };
};
```

## See Also

- [INVENTORY.md](INVENTORY.md) - Host inventory configuration guide
- [USER_CONFIGURATION.md](../USER_CONFIGURATION.md) - User management guide
- [README.md](../README.md) - Main documentation

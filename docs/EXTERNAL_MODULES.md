# External Configuration Modules

This guide explains how to use external modules for system and user configurations in nixos-systems.

## Table of Contents

- [Overview](#overview)
- [System Modules](#system-modules)
- [User Modules](#user-modules)
- [Fetch Methods](#fetch-methods)
- [Templates](#templates)
- [Integration Details](#integration-details)

## Overview

External modules allow you to maintain configurations in separate Git repositories and reference them from `inventory.nix` (for systems) or `users.nix` (for users).

**Benefits:**
- **Separation:** Keep configs in separate repositories
- **Versioning:** Pin to specific commits for reproducibility
- **Reusability:** Share configurations across deployments
- **Flexibility:** Mix external modules with local overrides

## System Modules

External system modules provide complete NixOS configurations for hosts.

### Usage in inventory.nix

```nix
nix-lxc = {
  devices = {
    # Traditional inline configuration
    "local-server" = {
      ugaif.users.admin.enable = true;
      services.nginx.enable = true;
    };
    
    # External module from Git
    "remote-server" = builtins.fetchGit {
      url = "https://github.com/org/server-config";
      rev = "abc123...";  # Pin to specific commit
    };
  };
};
```

### External Repository Structure

```
server-config/
├── default.nix    # Required: NixOS module
└── README.md      # Optional: Documentation
```

**default.nix:**
```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
  # Your NixOS configuration
  services.nginx = {
    enable = true;
    virtualHosts."example.com" = {
      root = "/var/www";
    };
  };
  
  # Use ugaif namespace options
  ugaif.users.admin.enable = true;
  ugaif.sw.type = "headless";
}
```

### What External Modules Receive

- **`inputs`** - All flake inputs (nixpkgs, home-manager, etc.)
- **`config`** - Full NixOS configuration
- **`lib`** - Nixpkgs library functions
- **`pkgs`** - Package set

### Module Integration Order

When a host is built, modules are loaded in this order:

1. User NixOS modules (from `users.nix` - `nixos.nix` files)
2. Host type module (from `hosts/types/`)
3. Configuration overrides (from `inventory.nix`)
4. Hostname assignment
5. External system module (if using `builtins.fetchGit`)

Later modules can override earlier ones using standard NixOS module precedence.

### Template

Create a new system module:

```bash
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#system
```

See [templates/system/](../templates/system/) for the complete template.

## User Modules

External user modules provide home-manager configurations (dotfiles, packages, programs).

### Usage in users.nix

```nix
ugaif.users = {
  # External user module (dotfiles, home-manager, and user options)
  myuser = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";
  };

  # Inline user definition
  inlineuser = {
    description = "Inline User";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$...";
  };
};
```

### External Repository Structure

```
dotfiles/
├── user.nix     # Required: User options AND home-manager config
├── nixos.nix    # Optional: System-level config
└── config/      # Optional: Actual dotfiles
    ├── bashrc
    └── vimrc
```

**user.nix (required):**
```nix
{ inputs, ... }:
{ config, lib, pkgs, osConfig ? null, ... }:
{
  # ========== User Account Configuration ==========
  ugaif.users.myusername = {
    description = "Your Full Name";
    shell = pkgs.zsh;
    hashedPassword = "!";
    opensshKeys = [ "ssh-ed25519 AAAA..." ];
    useZshTheme = true;
    useNvimPlugins = true;
  };

  # ========== Home Manager Configuration ==========
  # Packages
  home.packages = with pkgs; [
    vim
    git
    htop
  ] ++ lib.optional (osConfig.ugaif.sw.type or null == "desktop") firefox;
  
  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
  };
  
  # Manage dotfiles
  home.file.".bashrc".source = ./dotfiles/bashrc;
}
```

**nixos.nix (optional):**
```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
  # System-level configuration for this user
  users.users.myuser.extraGroups = [ "docker" ];
  environment.systemPackages = [ pkgs.docker ];
}
```

### What User Modules Receive

**In user.nix:**
- **`inputs`** - Flake inputs (nixpkgs, home-manager, etc.)
- **`config`** - Home-manager configuration
- **`lib`** - Nixpkgs library functions
- **`pkgs`** - Package set
- **`osConfig`** - OS-level configuration (read-only)

**In nixos.nix:**
- **`inputs`** - Flake inputs
- **`config`** - NixOS configuration
- **`lib`** - Nixpkgs library functions  
- **`pkgs`** - Package set

### User Options in users.nix

```nix
username = {
  # Identity
  description = "Full Name";
  
  # External configuration
  external = builtins.fetchGit { ... };
  # System settings
  extraGroups = [ "wheel" "networkmanager" ];
  hashedPassword = "$6$...";
  opensshKeys = [ "ssh-ed25519 ..." ];
  shell = pkgs.zsh;
  
  # Theme integration
  useZshTheme = true;      # Apply system zsh theme (default: true)
  useNvimPlugins = true;   # Apply system nvim config (default: true)
  
  # Enable on specific systems (see docs/INVENTORY.md)
  enable = false;  # Set in inventory.nix via ugaif.users.username.enable
};
```

### Template

Create a new user module:

```bash
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#user
```

See [templates/user/](../templates/user/) for the complete template.

## Fetch Methods

### Recommended: fetchGit with Revision

Pin to a specific commit for reproducibility:

```nix
builtins.fetchGit {
  url = "https://github.com/user/repo";
  rev = "abc123def456...";  # Full commit hash (40 characters)
  ref = "main";              # Optional: branch name
}
```

**Finding the commit hash:**
```bash
# Latest commit on main branch
git ls-remote https://github.com/user/repo main

# Or from a local clone
git rev-parse HEAD
```

### fetchGit with Branch (Less Reproducible)

Always fetches latest from branch:

```nix
builtins.fetchGit {
  url = "https://github.com/user/repo";
  ref = "develop";
}
```

⚠️ **Warning:** Builds may not be reproducible as the branch HEAD can change.

### fetchTarball (For Releases)

Download specific release archives:

```nix
builtins.fetchTarball {
  url = "https://github.com/user/repo/archive/v1.0.0.tar.gz";
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
```

**Get the hash:**
```bash
nix-prefetch-url --unpack https://github.com/user/repo/archive/v1.0.0.tar.gz
```

### Local Path (For Testing)

Use local directories during development:

```nix
/home/username/dev/my-config

# Or relative to repository
./my-local-config
```

⚠️ **Warning:** Only for testing. Use Git-based methods for production.

## Templates

### System Module Template

```bash
# Initialize in new directory
mkdir my-server-config
cd my-server-config
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#system
```

See [templates/system/README.md](../templates/system/README.md) for detailed usage.

### User Module Template

```bash
# Initialize in new directory
mkdir my-dotfiles
cd my-dotfiles
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#user
```

See [templates/user/README.md](../templates/user/README.md) for detailed usage.

## Integration Details

### Detection Logic

The system automatically detects external modules when a device or user value is:
- A path (`builtins.isPath`)
- A string starting with `/` (absolute path)
- A derivation (`lib.isDerivation`)
- An attrset with `outPath` attribute (result of `fetchGit`/`fetchTarball`)

### System Module Integration

External system modules are imported and merged into the NixOS configuration:

```nix
import externalModulePath { inherit inputs; }
```

They can use all standard NixOS options plus `ugaif.*` namespace options.

### User Module Integration

External user modules are loaded in two contexts:

**User options (NixOS module context):**
```nix
import (externalPath + "/user.nix") { inherit inputs; }
# Evaluated as NixOS module to extract ugaif.users.<username> options
```

**Home-manager configuration:**
```nix
import (externalPath + "/user.nix") { inherit inputs; }
# Imported into home-manager for home.*, programs.*, services.* options
```

**System-level config (optional):**
```nix
import (externalPath + "/nixos.nix") { inherit inputs; }
# If present, imported as NixOS module for system-level configuration
```

### Combining External and Local Config

You can mix external modules with local overrides:

```nix
nix-lxc = {
  devices = {
    "server" = builtins.fetchGit {
      url = "https://github.com/org/base-config";
      rev = "abc123...";
    };
  };
  overrides = {
    # Apply to all devices, including external ones
    ugaif.users.admin.enable = true;
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
};
```

### Minimal User Module

**user.nix:**
```nix
{ inputs, ... }:
{ config, lib, pkgs, osConfig ? null, ... }:
{
  # User account options
  ugaif.users.myusername = {
    description = "My Name";
    shell = pkgs.zsh;
    hashedPassword = "!";
  };
  
  # Home-manager config
  home.packages = with pkgs; [ vim git ];
}
```

### Full User Module with Dotfiles

```
dotfiles/
├── user.nix
├── nixos.nix
└── config/
    ├── bashrc
    ├── vimrc
    └── gitconfig
```

**user.nix:**
```nix
{ inputs, ... }:
{ config, lib, pkgs, osConfig ? null, ... }:
{
  # User account configuration
  ugaif.users.myusername = {
    description = "My Full Name";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPassword = "!";
    opensshKeys = [ "ssh-ed25519 AAAA..." ];
    useZshTheme = true;
    useNvimPlugins = true;
  };
  
  # Home-manager configuration
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
  ] ++ lib.optional (osConfig.ugaif.sw.type or null == "desktop") firefox;
  
  programs.git = {
    enable = true;
    userName = "My Full Name";
    userEmail = "me@example.com";
    extraConfig.init.defaultBranch = "main";
  };
  
  home.file = {
    ".bashrc".source = ./config/bashrc;
    ".vimrc".source = ./config/vimrc;
    ".gitconfig".source = ./config/gitconfig;
  };
}
```

## See Also

- [INVENTORY.md](INVENTORY.md) - Host configuration guide
- [USER_CONFIGURATION.md](USER_CONFIGURATION.md) - User management guide
- [NAMESPACE.md](NAMESPACE.md) - Configuration options reference
- [templates/system/](../templates/system/) - System module template
- [templates/user/](../templates/user/) - User module template
- [README.md](../README.md) - Main documentation

# UGA Innovation Factory - NixOS Systems

This repository contains the NixOS configuration for the Innovation Factory's fleet of laptops, desktops, surface tablets, and containers. It provides a declarative, reproducible system configuration using Nix flakes.

## Table of Contents

- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Configuration Namespace](#configuration-namespace)
- [User Management](#user-management)
- [Host Configuration](#host-configuration)
- [External Modules](#external-modules)
- [Building Artifacts](#building-artifacts)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

## Quick Start

### For End Users: Updating Your System

Update your system to the latest configuration from GitHub:

```bash
update-system
```

This command automatically:
- Fetches the latest configuration
- Rebuilds your system
- Uses remote builders on Surface tablets to speed up builds

**Note:** If you use external user configurations (personal dotfiles), run `sudo nixos-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems --impure` instead.

### For Administrators: Applying Configuration Changes

1. Make changes to configuration files
2. Test the configuration builds:
   ```bash
   nix flake check
   ```
3. Commit and push changes:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```
4. Users can now run `update-system` to get the changes

## Repository Structure

```
nixos-systems/
├── flake.nix           # Flake entry point with inputs/outputs
├── inventory.nix       # Fleet inventory (hosts, types, counts)
├── users.nix           # User account definitions
├── hosts/              # Host generation logic and hardware types
│   ├── default.nix     # Core host generation functions
│   ├── types/          # Hardware type definitions
│   │   ├── nix-desktop.nix
│   │   ├── nix-laptop.nix
│   │   ├── nix-surface.nix
│   │   ├── nix-lxc.nix
│   │   ├── nix-wsl.nix
│   │   └── nix-ephemeral.nix
│   └── user-config.nix # User configuration integration
├── sw/                 # Software configurations by system type
│   ├── desktop/        # Desktop system software
│   ├── tablet-kiosk/   # Surface tablet kiosk mode
│   ├── stateless-kiosk/# Stateless kiosk systems
│   ├── headless/       # Headless server systems
│   ├── ghostty.nix     # Ghostty terminal emulator
│   ├── nvim.nix        # Neovim configuration
│   ├── python.nix      # Python development tools
│   ├── theme.nix       # UI theme configuration
│   └── updater.nix     # System update service
├── installer/          # Build artifact generation
│   ├── artifacts.nix   # ISO, LXC, Proxmox builds
│   ├── auto-install.nix # Automated installer
│   └── modules.nix     # Exported modules
├── templates/          # Templates for external configs
│   ├── system/         # System configuration template
│   └── user/           # User configuration template
└── assets/             # Assets (Plymouth theme, etc.)
```

## Configuration Namespace

All UGA Innovation Factory-specific options are under the `ugaif` namespace:

### `ugaif.host` - Hardware Configuration
- **`ugaif.host.filesystem`**: Disk device and swap size settings
  - `ugaif.host.filesystem.device` - Boot disk device (default: `/dev/sda`)
  - `ugaif.host.filesystem.swapSize` - Swap file size (default: `"32G"`)
- **`ugaif.host.buildMethods`**: List of supported artifact types (`["iso"]`, `["lxc", "proxmox"]`, etc.)
- **`ugaif.host.useHostPrefix`**: Whether to prepend type prefix to hostname (default: `true`)
- **`ugaif.host.wsl`**: WSL-specific configuration
  - `ugaif.host.wsl.user` - Default WSL user

### `ugaif.sw` - Software Configuration
- **`ugaif.sw.enable`**: Enable software configuration module (default: `true`)
- **`ugaif.sw.type`**: System type - `"desktop"`, `"tablet-kiosk"`, `"stateless-kiosk"`, or `"headless"`
- **`ugaif.sw.kioskUrl`**: URL for kiosk mode browsers
- **`ugaif.sw.python`**: Python development tools configuration
  - `ugaif.sw.python.enable` - Enable Python tools (pixi, uv)
- **`ugaif.sw.remoteBuild`**: Remote build configuration
  - `ugaif.sw.remoteBuild.enable` - Use remote builders (default: enabled on tablets)
  - `ugaif.sw.remoteBuild.hosts` - List of build servers
- **`ugaif.sw.extraPackages`**: Additional system packages to install

### `ugaif.users` - User Management
- **`ugaif.users.accounts`**: Attrset of user definitions with account settings
- **`ugaif.users.enabledUsers`**: List of users to enable on this system (default: `["root", "engr-ugaif"]`)
- **`ugaif.forUser`**: Convenience option to set up a system for a specific user (sets `enabledUsers` and `wslUser`)

### Prerequisites

To work with this repository, install Nix with flakes support:

```bash
# Recommended: Determinate Systems installer (includes flakes)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Alternative: Official installer (requires enabling flakes)
sh <(curl -L https://nixos.org/nix/install) --daemon
```

## User Management

### Understanding User Configuration

Users are defined in `users.nix` but are **not enabled by default** on all systems. Each system must explicitly enable users via `ugaif.users.enabledUsers` in `inventory.nix`.

**Default enabled users on all systems:**
- `root` - System administrator
- `engr-ugaif` - Innovation Factory default account

### Adding a New User

1. Edit `users.nix` and add a new user:

```nix
ugaif.users.accounts = {
  # ... existing users ...
  
  myuser = {
    description = "My Full Name";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;  # or pkgs.bash, pkgs.fish
    hashedPassword = "$6$...";  # Generate with: mkpasswd -m sha-512
    opensshKeys = [
      "ssh-ed25519 AAAA... user@machine"
    ];
    # enable = false;  # Will be enabled per-system in inventory.nix
  };
};
```

2. Generate a hashed password:
```bash
mkpasswd -m sha-512  # Enter password when prompted
```

3. Enable the user on specific hosts in `inventory.nix`:

```nix
nix-laptop = {
  devices = 2;
  overrides.extraUsers = [ "myuser" ];  # Enables on all nix-laptop hosts
};

# Or for individual devices:
nix-desktop = {
  devices = {
    "1".extraUsers = [ "myuser" "otheruser" ];
  };
};
```

### User Configuration Options

Each user in `users.nix` can have:

```nix
myuser = {
  description = "Full Name";              # User's full name
  isNormalUser = true;                    # Default: true
  extraGroups = [ ... ];                  # Additional groups (wheel, docker, etc.)
  shell = pkgs.zsh;                       # Login shell
  hashedPassword = "$6$...";              # Hashed password
  opensshKeys = [ "ssh-ed25519 ..." ];    # SSH public keys
  homePackages = with pkgs; [ ... ];      # Home-manager packages (if no external config)
  useZshTheme = true;                     # Use system Zsh theme (default: true)
  useNvimPlugins = true;                  # Use system Neovim config (default: true)
  
  # External home-manager configuration (optional)
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";
  };
};
```

### External User Configuration

Users can maintain their dotfiles and home-manager configuration in separate repositories. See [External Modules](#external-modules) and [USER_CONFIGURATION.md](USER_CONFIGURATION.md) for details.

**Quick example:**
```nix
myuser = {
  description = "My Name";
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "commit-hash";
  };
};
```

The external repository should contain:
- `home.nix` (required) - Home-manager configuration
- `nixos.nix` (optional) - System-level user configuration

**Create a template:**
```bash
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#user
```

## Host Configuration

### Understanding Inventory Structure

The `inventory.nix` file defines all hosts in the fleet using a flexible system:

**Hostname Generation Rules:**
- Numeric suffixes: no dash (e.g., `nix-laptop1`, `nix-laptop2`)
- Non-numeric suffixes: with dash (e.g., `nix-laptop-alpha`, `nix-laptop-beta`)  
- Set `ugaif.host.useHostPrefix = false` to use suffix as full hostname

### Adding Hosts

**Method 1: Quick count (simplest)**
```nix
nix-laptop = {
  devices = 5;  # Creates: nix-laptop1, nix-laptop2, ..., nix-laptop5
};
```

**Method 2: Explicit count with overrides**
```nix
nix-laptop = {
  devices = 5;
  overrides = {
    # Applied to ALL nix-laptop hosts
    extraUsers = [ "student" ];
    ugaif.sw.extraPackages = with pkgs; [ vim git ];
  };
};
```

**Method 3: Individual device configuration**
```nix
nix-surface = {
  devices = {
    "1".ugaif.sw.kioskUrl = "https://dashboard1.example.com";
    "2".ugaif.sw.kioskUrl = "https://dashboard2.example.com";
    "3".ugaif.sw.kioskUrl = "https://dashboard3.example.com";
  };
};
```

**Method 4: Mixed (default count + custom devices)**
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

### Device Configuration Options

**Convenience shortcuts** (automatically converted to proper options):
- `extraUsers` → `ugaif.users.enabledUsers`
- `hostname` → Custom hostname (overrides default naming)
- `buildMethods` → `ugaif.host.buildMethods`
- `wslUser` → `ugaif.host.wsl.user`

**Direct configuration** (any NixOS or ugaif option):
```nix
"1" = {
  # Convenience
  extraUsers = [ "myuser" ];
  
  # UGAIF options
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

This automatically:
- Adds user to `extraUsers` (enables the account)
- Sets `ugaif.host.wsl.user` to the username (for WSL)

### External System Configuration

For complex configurations, use external modules. See [External Modules](#external-modules) and [EXTERNAL_MODULES.md](EXTERNAL_MODULES.md).

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

**Create a template:**
```bash
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#system
```

## External Modules

External modules allow you to maintain user or system configurations in separate Git repositories and reference them from `users.nix` or `inventory.nix`.

### Benefits

- **Separation**: Keep configs in separate repositories
- **Versioning**: Pin to specific commits for reproducibility
- **Reusability**: Share configurations across deployments
- **Flexibility**: Mix external modules with local overrides

### Templates

Initialize a new external configuration:

```bash
# User configuration (home-manager, dotfiles)
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#user

# System configuration (services, packages, hardware)
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#system
```

### User Module Example

In `users.nix`:
```nix
myuser = {
  description = "My Name";
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";  # Pin to specific commit
  };
};
```

External repository structure:
```
dotfiles/
├── home.nix    # Required: Home-manager configuration
└── nixos.nix   # Optional: System-level user configuration
```

See [USER_CONFIGURATION.md](USER_CONFIGURATION.md) and [templates/user/](templates/user/) for details.

### System Module Example

In `inventory.nix`:
```nix
nix-lxc = {
  devices = {
    "custom-server" = builtins.fetchGit {
      url = "https://github.com/org/server-config";
      rev = "abc123...";
    };
  };
};
```

External repository structure:
```
server-config/
└── default.nix  # Required: NixOS module
```

See [EXTERNAL_MODULES.md](EXTERNAL_MODULES.md) and [templates/system/](templates/system/) for details.

### Fetch Methods

**Recommended: fetchGit with revision**
```nix
builtins.fetchGit {
  url = "https://github.com/user/repo";
  rev = "abc123def456...";  # Full commit hash
  ref = "main";              # Optional: branch name
}
```

**Local path (for testing)**
```nix
/path/to/local/config
```

**Tarball (for releases)**
```nix
builtins.fetchTarball {
  url = "https://github.com/user/repo/archive/v1.0.0.tar.gz";
  sha256 = "sha256:...";
}
```

## Building Artifacts

Build installation media and container images from this flake.

### Installer ISOs

Build an auto-install ISO for a specific host:

```bash
# Build locally
nix build github:UGA-Innovation-Factory/nixos-systems#installer-iso-nix-laptop1

# Build using remote builder
nix build github:UGA-Innovation-Factory/nixos-systems#installer-iso-nix-laptop1 \
  --builders "ssh://engr-ugaif@nix-builder x86_64-linux"
```

Result: `result/iso/nixos-*.iso`

### Available Artifacts

```bash
# List all available builds
nix flake show github:UGA-Innovation-Factory/nixos-systems

# Common artifacts:
nix build .#installer-iso-nix-laptop1    # Installer ISO
nix build .#iso-nix-ephemeral1           # Live ISO (no installer)
nix build .#ipxe-nix-ephemeral1          # iPXE netboot
nix build .#lxc-nix-builder              # LXC container tarball
nix build .#proxmox-nix-builder          # Proxmox VMA
```

### Using Remote Builders

Speed up builds by offloading to a build server:

```bash
# In ~/.config/nix/nix.conf or /etc/nix/nix.conf:
builders = ssh://engr-ugaif@nix-builder x86_64-linux

# Or use --builders flag for one-time builds
nix build ... --builders "ssh://engr-ugaif@nix-builder x86_64-linux"
```

## Development

### Testing Configuration Changes

Before committing changes:

```bash
# Check all configurations build correctly
nix flake check

# Check with verbose trace on error
nix flake check --show-trace

# Build a specific host configuration
nix build .#nixosConfigurations.nix-laptop1.config.system.build.toplevel

# Test rebuild locally
sudo nixos-rebuild test --flake .
```

### Manual System Rebuilds

For testing or emergency fixes:

```bash
# Rebuild current host from local directory
sudo nixos-rebuild switch --flake .

# Rebuild specific host
sudo nixos-rebuild switch --flake .#nix-laptop1

# Test without switching (temporary, doesn't persist reboot)
sudo nixos-rebuild test --flake .#nix-laptop1

# Rebuild from GitHub
sudo nixos-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems
```

### Updating Flake Inputs

Update nixpkgs, home-manager, and other dependencies:

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# After updating, test and commit
git add flake.lock
git commit -m "Update flake inputs"
```

### Python Development

All systems include `pixi` and `uv` for project-based Python environments:

**Pixi (recommended for projects):**
```bash
pixi init my-project
cd my-project
pixi add pandas numpy matplotlib
pixi run python script.py
```

**uv (quick virtual environments):**
```bash
uv venv
source .venv/bin/activate
uv pip install requests
```

### Adding Packages System-Wide

**To all desktop systems:**
- Edit `sw/desktop/programs.nix`

**To all tablet kiosks:**
- Edit `sw/tablet-kiosk/programs.nix`

**To all headless systems:**
- Edit `sw/headless/programs.nix`

**To specific hosts:**
- Add to `ugaif.sw.extraPackages` in `inventory.nix`

Example:
```nix
nix-laptop = {
  devices = 2;
  overrides = {
    ugaif.sw.extraPackages = with pkgs; [ vim docker ];
  };
};
```

### Changing System Type

System types are defined in `hosts/types/` and set the software profile:

- **`desktop`**: Full desktop environment (GNOME)
- **`tablet-kiosk`**: Surface tablets with kiosk mode browser
- **`stateless-kiosk`**: Diskless PXE boot kiosks
- **`headless`**: Servers and containers without GUI

To change a host's type, edit the type module it imports in `hosts/types/`.

## Troubleshooting

### Common Issues

**"error: executing 'git': No such file or directory"**
- The `update-system` service needs git in PATH (fixed in latest version)
- Workaround: Run `sudo nixos-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems` manually

**Build errors after flake update**
```bash
# Check what changed
git diff flake.lock

# Try with show-trace for details
nix flake check --show-trace

# Revert if needed
git checkout flake.lock
```

**External modules not loading**
- Ensure repository is accessible (public or SSH configured)
- Module must export proper structure (see templates)
- For users: requires `home.nix` and optionally `nixos.nix`
- For systems: requires `default.nix` that accepts `{ inputs, ... }`

**Remote build failures**
```bash
# Test SSH access
ssh engr-ugaif@nix-builder

# Check builder disk space
ssh engr-ugaif@nix-builder df -h

# Temporarily disable remote builds in inventory.nix:
ugaif.sw.remoteBuild.enable = false;
```

**"dirty git tree" warnings**
- Commit or stash uncommitted changes
- These warnings don't prevent builds but affect reproducibility

### Getting Help

- Check documentation: [USER_CONFIGURATION.md](USER_CONFIGURATION.md), [EXTERNAL_MODULES.md](EXTERNAL_MODULES.md)
- Review templates: `templates/user/` and `templates/system/`
- Contact Innovation Factory IT team

### Useful Commands

```bash
# Show all available outputs
nix flake show

# Evaluate a specific option
nix eval .#nixosConfigurations.nix-laptop1.config.networking.hostName

# List all hosts
nix eval .#nixosConfigurations --apply builtins.attrNames

# Check flake metadata
nix flake metadata

# Update and show what changed
nix flake update && git diff flake.lock
```

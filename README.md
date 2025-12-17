# UGA Innovation Factory - NixOS Systems

[![CI](https://github.com/UGA-Innovation-Factory/nixos-systems/actions/workflows/ci.yml/badge.svg)](https://github.com/UGA-Innovation-Factory/nixos-systems/actions/workflows/ci.yml)

This repository contains the NixOS configuration for the Innovation Factory's fleet of laptops, desktops, Surface tablets, and containers. It provides a declarative, reproducible system configuration using Nix flakes.

## Documentation

- **[Quick Start](#quick-start)** - Get started in 5 minutes
- **[docs/INVENTORY.md](docs/INVENTORY.md)** - Configure hosts and fleet inventory
- **[docs/NAMESPACE.md](docs/NAMESPACE.md)** - Configuration options reference (`ugaif.*`)
- **[docs/USER_CONFIGURATION.md](docs/USER_CONFIGURATION.md)** - User account management
- **[docs/EXTERNAL_MODULES.md](docs/EXTERNAL_MODULES.md)** - External configuration modules
- **[docs/BUILDING.md](docs/BUILDING.md)** - Build ISOs and container images
- **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Development and testing workflow

## Quick Start

### For End Users

Update your system to the latest configuration:

```bash
update-system
```

This command automatically fetches the latest configuration, rebuilds your system, and uses remote builders on Surface tablets to speed up builds.

**Note:** If you use external user configurations (personal dotfiles), run:
```bash
sudo nixos-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems --impure
```

### For Administrators

```bash
# 1. Make changes to configuration files
vim inventory.nix

# 2. Test configuration
nix flake check

# 3. Format code
nix fmt

# 4. Commit and push
git add .
git commit -m "Description of changes"
git push
```

Users can now run `update-system` to get the changes.

**See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for detailed development workflow.**

## Repository Structure

```
nixos-systems/
├── flake.nix           # Flake entry point
├── inventory.nix       # Fleet inventory - Define hosts here
├── users.nix           # User accounts - Define users here
├── hosts/              # Host generation logic
│   ├── types/          # Hardware types (desktop, laptop, surface, lxc, wsl, ephemeral)
│   └── ...
├── sw/                 # Software configurations by system type
│   ├── desktop/        # Full desktop environment
│   ├── tablet-kiosk/   # Surface kiosk mode
│   ├── stateless-kiosk/# Diskless PXE kiosks
│   ├── headless/       # Servers and containers
│   └── ...
├── installer/          # ISO and container builds
├── templates/          # Templates for external configs
│   ├── system/         # System configuration template
│   └── user/           # User configuration template
├── docs/               # Documentation
│   ├── INVENTORY.md    # Host configuration guide
│   ├── NAMESPACE.md    # Option reference
│   ├── BUILDING.md     # Building artifacts
│   └── DEVELOPMENT.md  # Development guide
└── assets/             # Assets (Plymouth theme, etc.)
```

## Configuration Overview

All Innovation Factory options use the `ugaif.*` namespace. See **[docs/NAMESPACE.md](docs/NAMESPACE.md)** for complete reference.

**Quick examples:**

```nix
# Host configuration
ugaif.host.filesystem.device = "/dev/nvme0n1";
ugaif.host.filesystem.swapSize = "64G";

# Software configuration  
ugaif.sw.type = "desktop";  # or "headless", "tablet-kiosk"
ugaif.sw.extraPackages = with pkgs; [ vim docker ];

# User management
ugaif.users.myuser.enable = true;
ugaif.forUser = "myuser";  # Convenience shortcut
```

## Prerequisites

To work with this repository, install Nix with flakes support:

```bash
# Recommended: Determinate Systems installer (includes flakes)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Alternative: Official installer (requires enabling flakes manually)
sh <(curl -L https://nixos.org/nix/install) --daemon
```

## Common Tasks

### Adding a New User

1. Edit `users.nix`:

```nix
myuser = {
  description = "My Full Name";
  extraGroups = [ "wheel" "networkmanager" ];
  shell = pkgs.zsh;
  hashedPassword = "$6$...";  # Generate with: mkpasswd -m sha-512
  opensshKeys = [ "ssh-ed25519 AAAA... user@host" ];
};
```

2. Enable on hosts in `inventory.nix`:

```nix
nix-laptop = {
  devices = 2;
  overrides.ugaif.users.myuser.enable = true;
};
```

**See [docs/USER_CONFIGURATION.md](docs/USER_CONFIGURATION.md) for complete user management guide.**

### Adding Hosts

Edit `inventory.nix`:

```nix
# Simple: Create 5 laptops
nix-laptop = {
  devices = 5;  # Creates nix-laptop1 through nix-laptop5
};

# With configuration
nix-surface = {
  devices = {
    "1".ugaif.sw.kioskUrl = "https://dashboard1.example.com";
    "2".ugaif.sw.kioskUrl = "https://dashboard2.example.com";
  };
};

# With overrides for all devices
nix-desktop = {
  devices = 3;
  overrides = {
    ugaif.users.student.enable = true;
    ugaif.sw.extraPackages = with pkgs; [ vim ];
  };
};
```

**See [docs/INVENTORY.md](docs/INVENTORY.md) for complete host configuration guide.**

### Using External Configurations

Users and systems can reference external Git repositories for configuration:

```nix
# In users.nix - External dotfiles
myuser = {
  description = "My Name";
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";
  };
};

# In inventory.nix - External system config
nix-lxc = {
  devices."server" = builtins.fetchGit {
    url = "https://github.com/org/server-config";
    rev = "abc123...";
  };
};
```

**Create templates:**
```bash
# User configuration (dotfiles)
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#user

# System configuration
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#system
```

**See [docs/EXTERNAL_MODULES.md](docs/EXTERNAL_MODULES.md) for complete guide.**

### Building Installation Media

```bash
# Build installer ISO
nix build github:UGA-Innovation-Factory/nixos-systems#installer-iso-nix-laptop1

# Build LXC container
nix build .#lxc-nix-builder

# List all available artifacts
nix flake show github:UGA-Innovation-Factory/nixos-systems
```

**See [docs/BUILDING.md](docs/BUILDING.md) for complete guide on building ISOs, containers, and using remote builders.**

## System Types

- **`desktop`** - Full GNOME desktop environment
- **`tablet-kiosk`** - Surface tablets in kiosk mode
- **`stateless-kiosk`** - Diskless PXE boot kiosks  
- **`headless`** - Servers and containers (no GUI)

Set via `ugaif.sw.type` option. See [docs/NAMESPACE.md](docs/NAMESPACE.md) for all options.

## Development

**Quick commands:**
```bash
nix flake check           # Validate all configurations
nix fmt                   # Format code
nix flake update          # Update dependencies
nix build .#installer-iso-nix-laptop1  # Build specific artifact
```

**See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for complete development guide.**

## Troubleshooting

**Common issues:**

- **Build errors:** Run `nix flake check --show-trace` for details
- **External modules not loading:** Check repository access and module structure (see templates)
- **Remote build failures:** Test SSH access: `ssh engr-ugaif@nix-builder`
- **Out of disk space:** Run `nix-collect-garbage -d && nix store optimise`

**Useful commands:**
```bash
nix flake show                    # List all available outputs
nix flake metadata                # Show flake info
nix eval .#nixosConfigurations --apply builtins.attrNames  # List all hosts
```

**See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) and [docs/BUILDING.md](docs/BUILDING.md) for detailed troubleshooting.**

## Getting Help

- Review documentation in `docs/` directory
- Check templates: `templates/user/` and `templates/system/`  
- Contact Innovation Factory IT team

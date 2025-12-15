# UGA Innovation Factory - NixOS Systems

This repository contains the NixOS configuration for the Innovation Factory's fleet of laptops, desktops, and surface tablets. It provides a declarative, reproducible system configuration using Nix flakes.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Configuration Namespace](#configuration-namespace)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Building Artifacts](#building-artifacts-isos-lxc-proxmox)
- [Configuration Guide](#configuration-guide)
  - [User Management](#user-management)
  - [Host Configuration](#host-configuration)
- [External Flake Templates](#external-flake-templates)
- [Development](#development)

## Repository Structure

- **`flake.nix`**: The entry point for the configuration.
- **`inventory.nix`**: Defines the fleet inventory (host types, counts, and device-specific overrides).
- **`users.nix`**: Defines user accounts, passwords, and package sets.
- **`hosts/`**: Contains the logic for generating host configurations and hardware-specific types.
- **`sw/`**: Software modules (Desktop, Kiosk, Python, Neovim, etc.).

## Configuration Namespace

All UGA Innovation Factory-specific NixOS options are organized under the `ugaif` namespace to clearly distinguish them from standard NixOS options. The main option groups are:

- **`ugaif.host`**: Hardware and host-level configuration
  - `ugaif.host.filesystem`: Disk device and swap size settings
  - `ugaif.host.buildMethods`: Supported artifact build methods (ISO, LXC, etc.)
  - `ugaif.host.wsl`: WSL-specific configuration
  
- **`ugaif.sw`**: Software and system type configuration
  - `ugaif.sw.enable`: Enable the software configuration module
  - `ugaif.sw.type`: System type (`desktop`, `tablet-kiosk`, `headless`, `stateless-kiosk`)
  - `ugaif.sw.kioskUrl`: URL for kiosk mode browsers
  - `ugaif.sw.python`: Python development tools settings
  - `ugaif.sw.remoteBuild`: Remote build configuration
  
- **`ugaif.users`**: User account management
  - `ugaif.users.accounts`: User account definitions
  - `ugaif.users.enabledUsers`: List of users enabled on the system
  - `ugaif.users.shell`: Default shell for users

## Prerequisites

To work with this repository on a non-NixOS system (like macOS or another Linux distro), you need to install Nix. We recommend the Determinate Systems installer for a reliable and feature-complete setup (including Flakes support out of the box).

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Quick Start

### For End Users: Updating Your System

The easiest way to update your system is using the included `update-system` utility:

```bash
update-system
```

This command:
- Pulls the latest configuration from GitHub
- Rebuilds the system with any changes
- Automatically uses remote builders if you're on a Surface tablet

If you use external flakes (personal dotfiles), add the `--impure` flag:

```bash
update-system --impure
```

### For Administrators: Managing the Fleet

#### Applying Configuration Changes

After modifying files in this repository:

```bash
# Test the configuration builds
nix flake check

# Push changes to GitHub
git add .
git commit -m "Description of changes"
git push

# Users can then run: update-system
```

#### Manual Rebuilds

For testing or emergency fixes:

```bash
# Rebuild current host
sudo nixos-rebuild switch --flake .

# Rebuild specific host
sudo nixos-rebuild switch --flake .#nix-laptop1

# Test without switching
sudo nixos-rebuild test --flake .#nix-laptop1
```

#### Updating Dependencies

Update nixpkgs, home-manager, and other flake inputs:

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# After updating, test and commit the new flake.lock
git add flake.lock
git commit -m "Update flake inputs"
```

## Building Artifacts (ISOs, LXC, Proxmox)

You can generate installation media and virtual machine images directly from this flake.

### Installer ISOs

To build an auto-install ISO for a specific host (e.g., `nix-laptop1`):

```bash
nix build github:UGA-Innovation-Factory/nixos-systems#installer-iso-nix-laptop1
```

To speed up the build by offloading to a powerful build server (e.g., `nix-builder`), use the `--builders` flag:

```bash
nix build github:UGA-Innovation-Factory/nixos-systems#installer-iso-nix-laptop1 \
  --builders "ssh://engr-ugaif@nix-builder x86_64-linux - 16 1 big-parallel"
```

The resulting ISO will be in `result/iso/`.

### LXC / Proxmox Images

For hosts configured as containers (e.g., `nix-lxc1`), you can build LXC tarballs or Proxmox VMA archives:

```bash
# Build LXC tarball
nix build .#lxc-nix-lxc1

# Build Proxmox VMA
nix build .#proxmox-nix-lxc1
```



## Configuration Guide

### User Management

#### Adding a New User

1.  Open `users.nix`.
2.  Add a new entry to `ugaif.users.accounts`:

```nix
ugaif.users.accounts = {
  # ... existing users ...
  
  newuser = {
    description = "New User Name";
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$6$..."; # Generate with: mkpasswd -m sha-512
    opensshKeys = [ "ssh-ed25519 AAAA..." ];
  };
};
```

3.  Generate a hashed password using `mkpasswd -m sha-512` (requires `whois` package).
4.  Commit and push the changes.

**Note:** Hashed passwords are for shared credentials only. For personal secrets, use external secret management.

#### Assigning Users to Hosts

By default, only `root` and `engr-ugaif` are enabled on all systems. To enable additional users on specific devices:

1.  Open `inventory.nix`.
2.  Locate the host type (e.g., `nix-laptop`).
3.  Add the user to the device's `extraUsers` list:

```nix
nix-laptop = {
  count = 2;
  devices = {
    "1".extraUsers = [ "newuser" "hdh20267" ];
  };
};
```

#### Using External Flakes for User Configuration

Users can manage their own dotfiles and configuration in a separate flake repository. This allows full control over shell configuration, editor settings, and Home Manager modules.

**Security Note:** External flakes run with the same privileges as the system configuration. Only use trusted flakes and pin to specific commits.

To enable this:

1.  Open `users.nix`.
2.  Set the `flakeUrl` for the user:

```nix
hdh20267 = {
  description = "User Name";
  extraGroups = [ "networkmanager" "wheel" ];
  hashedPassword = "$6$...";
  flakeUrl = "github:hdh20267/dotfiles";
  
  # Optional: Disable system defaults
  useZshTheme = false;      # Manage your own Zsh config
  useNvimPlugins = false;   # Manage your own Neovim config
};
```

The external flake must provide a `nixosModules.default` output. See [User Flake Template](#user-flake-for-usersnix) below for an example.

### Host Configuration

#### Adding a New Host

To add more devices of an existing type:

1.  Open `inventory.nix`.
2.  Increment the `count` for the host type:

```nix
nix-laptop.count = 3;  # Creates nix-laptop1, nix-laptop2, nix-laptop3
```

#### Device-Specific Configuration Overrides

You can customize individual devices in `inventory.nix` using either shortcut keys or direct configuration.

**Shortcut Keys** (for common settings):
- `extraUsers` → Sets `ugaif.users.enabledUsers`
- `hostname` → Sets a custom hostname (default: `{type}{number}`)
- `buildMethods` → Sets `ugaif.host.buildMethods`
- `wslUser` → Sets `ugaif.host.wsl.user`
- `flakeUrl` → Imports an external system flake

**Direct Configuration** (using the `ugaif` namespace or standard NixOS options):

```nix
nix-laptop = {
  count = 2;
  devices = {
    "1" = {
      # Shortcut keys
      extraUsers = [ "hdh20267" ];
      hostname = "laptop-special";
      
      # UGAIF options
      ugaif.host.filesystem.swapSize = "64G";
      ugaif.sw.extraPackages = with pkgs; [ docker vim ];
      
      # Standard NixOS options
      networking.firewall.enable = false;
      services.openssh.enable = true;
    };
  };
};
```

#### Customizing Kiosk URLs for Surface Tablets

Surface tablets run in kiosk mode with a full-screen Chromium browser. Set the URL per-device:

```nix
nix-surface = {
  count = 3;
  devices = {
    "1".ugaif.sw.kioskUrl = "https://ha.factory.uga.edu/dashboard-1";
    "2".ugaif.sw.kioskUrl = "https://ha.factory.uga.edu/dashboard-2";
  };
};
```

#### Using External Flakes for System Configuration

For complex system customizations (Docker, custom services, hardware tweaks), use an external flake:

```nix
nix-laptop = {
  count = 2;
  devices = {
    "2".flakeUrl = "github:myuser/my-system-config";
  };
};
```

The external flake must provide a `nixosModules.default` output. See [System Flake Template](#system-flake-for-inventorynix) below for an example.

## External Flake Templates

If you're creating a flake to use with `flakeUrl`, use these templates as starting points.

**Important:** Do not specify `inputs` in your flake. This ensures your flake uses the exact same `nixpkgs` version as the main system, preventing version drift and saving disk space.

### User Flake (for `users.nix`)

Use this template for user-specific dotfiles, shell configuration, Home Manager modules, and overriding user account settings.

```nix
{
  description = "My User Configuration";

  # No inputs needed! We use the system's packages.

  outputs = { self }: {
    # This output is what nixos-systems looks for
    nixosModules.default = { pkgs, lib, ... }: {
      
      # 1. Override System-Level User Settings
      ugaif.users.accounts.hdh20267 = {
        shell = pkgs.fish;
        extraGroups = [ "docker" ];
        
        # Optional: Disable system defaults if you manage your own
        useZshTheme = false;
        useNvimPlugins = false;
      };
      
      # Enable programs needed for the shell
      programs.fish.enable = true;

      # 2. Define Home Manager Configuration
      home-manager.users.hdh20267 = { pkgs, ... }: {
        home.stateVersion = "25.11";
        
        home.packages = with pkgs; [ 
          ripgrep 
          bat 
          fzf
        ];

        programs.git = {
          enable = true;
          userName = "My Name";
          userEmail = "me@example.com";
        };
      };
    };
  };
}
```

### System Flake (for `inventory.nix`)

Use this template for host-specific system services (Docker, databases, web servers), hardware configuration tweaks, or system-wide packages.

```nix
{
  description = "My System Configuration Override";

  # No inputs needed! We use the system's packages.

  outputs = { self }: {
    # This output is what nixos-systems looks for
    nixosModules.default = { pkgs, lib, ... }: {
      environment.systemPackages = [ pkgs.docker ];
      
      virtualisation.docker.enable = true;
      
      # Example: Override hardware settings defined in the main repo
      ugaif.host.filesystem.swapSize = lib.mkForce "64G";

      # Example: Enable specific users
      ugaif.users.enabledUsers = [ "myuser" ];
      
      # Example: Add a custom binary cache
      nix.settings.substituters = [ "https://nix-community.cachix.org" ];
      nix.settings.trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };
  };
}
```

## Development

### Python Environment

All systems include `pixi` and `uv` for Python project management. Use these tools for project-specific environments instead of installing global Python packages (which can cause conflicts).

**Creating a new project with Pixi:**

```bash
pixi init my_project
cd my_project
pixi add pandas numpy matplotlib
pixi run python script.py
```

**Using uv for quick tasks:**

```bash
uv venv
source .venv/bin/activate
uv pip install requests
```

### Testing Changes Locally

Before pushing changes, verify your configuration builds correctly:

```bash
# Check all configurations
nix flake check

# Build a specific configuration
nix build .#nixosConfigurations.nix-laptop1.config.system.build.toplevel

# Test an ISO build
nix build .#installer-iso-nix-laptop1
```

### Common Configuration Patterns

#### Adding System Packages to All Hosts

Edit `sw/desktop/programs.nix` (or the appropriate type directory) to add packages to the base system:

```nix
basePackages = with pkgs; [
  htop
  vim
  git
  # Add your packages here
];
```

#### Changing Default User Shell

Edit `users.nix` to set a different shell for a specific user:

```nix
myuser = {
  description = "My User";
  shell = pkgs.fish;  # or pkgs.zsh, pkgs.bash
  # ... other settings
};
```

Then ensure the program is enabled in the system configuration (usually already done for common shells).

## Troubleshooting

### Flake Check Errors

If `nix flake check` fails, use `--show-trace` for detailed error information:

```bash
nix flake check --show-trace
```

### External Flakes Not Loading

If using `flakeUrl`, ensure:
1. The flake repository is public or you have SSH access configured
2. The flake has a `nixosModules.default` output
3. You're using `--impure` flag if the flake has impure operations

### Build Failures on Surface Tablets

Surface tablets automatically offload builds to remote builders. If builds fail:
1. Verify the remote builder is accessible: `ssh engr-ugaif@nix-builder`
2. Check remote builder has sufficient disk space: `df -h`
3. Try building locally with remote builds disabled by commenting out `ugaif.sw.remoteBuild.enable`

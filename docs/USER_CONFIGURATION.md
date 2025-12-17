# User Configuration Guide

Complete guide to managing user accounts in nixos-systems.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [User Account Options](#user-account-options)
- [External User Configurations](#external-user-configurations)
- [Enabling Users on Hosts](#enabling-users-on-hosts)
- [Password Management](#password-management)
- [SSH Keys](#ssh-keys)
- [Examples](#examples)

## Overview

Users are defined in `users.nix` but are **not enabled by default** on all systems. Each system must explicitly enable users in `inventory.nix`.

**Default enabled users:**
- `root` - System administrator
- `engr-ugaif` - Innovation Factory default account

## Quick Start

### 1. Define User in users.nix

```nix
ugaif.users = {
  myuser = {
    description = "My Full Name";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$...";  # Generate with: mkpasswd -m sha-512
    opensshKeys = [
      "ssh-ed25519 AAAA... user@machine"
    ];
  };
};
```

### 2. Enable User on Hosts

In `inventory.nix`:

```nix
nix-laptop = {
  devices = 2;
  overrides.ugaif.users.myuser.enable = true;  # Enables on all nix-laptop hosts
};

# Or for specific devices
nix-desktop = {
  devices = {
    "1".ugaif.users.myuser.enable = true;
    "2".ugaif.users.otheruser.enable = true;
  };
};

# Or use convenience option
nix-wsl = {
  devices."alice".ugaif.forUser = "alice-user";  # Automatically enables user
};
```

## User Account Options

Each user in `users.nix` can have the following options:

```nix
username = {
  # === Identity ===
  description = "Full Name";              # User's full name
  
  # === System Access ===
  isNormalUser = true;                    # Default: true (false for root)
  extraGroups = [                         # Additional Unix groups
    "wheel"                               # Sudo access
    "networkmanager"                      # Network configuration
    "docker"                              # Docker access
    "video"                               # Video device access
    "audio"                               # Audio device access
  ];
  shell = pkgs.zsh;                       # Login shell (default: pkgs.bash)
  hashedPassword = "$6$...";              # Hashed password (see below)
  
  # === SSH Access ===
  opensshKeys = [                         # SSH public keys
    "ssh-ed25519 AAAA... user@host"
    "ssh-rsa AAAA... user@otherhost"
  ];
  
  # === Home Configuration ===
  home = builtins.fetchGit { ... };       # External home-manager config (see below)
  
  # OR (if not using external config):
  homePackages = with pkgs; [             # User packages
    ripgrep
    fd
    bat
  ];
  extraImports = [ ./my-module.nix ];     # Additional home-manager modules
  
  # === Theme Integration ===
  useZshTheme = true;                     # Apply system Zsh theme (default: true)
  useNvimPlugins = true;                  # Apply system Neovim config (default: true)
  
  # === System Enablement ===
  enable = false;                         # Enable on this system (set in inventory.nix)
};
```

## External User Configurations

Users can maintain their dotfiles and home-manager configuration in separate Git repositories.

### Basic External Configuration

In `users.nix`:

```nix
myuser = {
  description = "My Name";
  extraGroups = [ "wheel" ];
  hashedPassword = "$6$...";
  
  # Point to external dotfiles repository
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";  # Pin to specific commit
  };
};
```

### External Repository Structure

```
dotfiles/
├── home.nix     # Required: Home-manager configuration
├── nixos.nix    # Optional: System-level configuration
└── config/      # Optional: Your dotfiles
    ├── bashrc
    ├── vimrc
    └── ...
```

**home.nix (required):**
```nix
{ inputs, ... }:
{ config, lib, pkgs, osConfig, ... }:
{
  home.packages = with pkgs; [ vim git htop ];
  
  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
  };
  
  home.file.".bashrc".source = ./config/bashrc;
}
```

**nixos.nix (optional):**
```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
  # System-level configuration
  users.users.myusername.extraGroups = [ "docker" ];
  environment.systemPackages = [ pkgs.docker ];
}
```

### What External Modules Receive

**In home.nix:**
- `inputs` - Flake inputs (nixpkgs, home-manager, etc.)
- `config` - Home-manager configuration
- `lib` - Nixpkgs library functions
- `pkgs` - Package set
- `osConfig` - OS-level configuration (read-only)

**In nixos.nix:**
- `inputs` - Flake inputs
- `config` - NixOS configuration
- `lib` - Nixpkgs library functions
- `pkgs` - Package set

### Alternative Configuration Methods

**Local path (for testing):**
```nix
home = /home/username/dev/dotfiles;
```

**Inline configuration:**
```nix
home = {
  home.packages = with pkgs; [ vim ];
  programs.git.enable = true;
};
```

**No external config (legacy):**
```nix
homePackages = with pkgs; [ vim git ];
# home = null;  # Default
```

### Create User Template

```bash
nix flake init -t github:UGA-Innovation-Factory/nixos-systems#user
```

See [templates/user/README.md](../templates/user/README.md) for complete template.

## Enabling Users on Hosts

Users must be explicitly enabled on each host in `inventory.nix`.

### Method 1: Enable in Overrides (All Devices)

```nix
nix-laptop = {
  devices = 5;
  overrides = {
    ugaif.users.student.enable = true;  # All 5 laptops get this user
  };
};
```

### Method 2: Enable per Device

```nix
nix-desktop = {
  devices = {
    "1".ugaif.users.alice.enable = true;
    "2".ugaif.users.bob.enable = true;
    "3" = {
      ugaif.users.alice.enable = true;
      ugaif.users.bob.enable = true;
    };
  };
};
```

### Method 3: Convenience Option (ugaif.forUser)

Quick setup for single-user systems:

```nix
nix-wsl = {
  devices = {
    "alice".ugaif.forUser = "alice-user";  # Automatically enables alice-user
    "bob".ugaif.forUser = "bob-user";
  };
};
```

This is equivalent to `ugaif.users.alice-user.enable = true`.

## Password Management

### Generate Hashed Password

```bash
mkpasswd -m sha-512
# Enter password when prompted
# Copy the output hash
```

### In users.nix

```nix
myuser = {
  hashedPassword = "$6$rounds=656000$...";  # Paste hash here
};
```

### Disable Password Login

```nix
myuser = {
  hashedPassword = "!";  # Locks password, SSH key only
  opensshKeys = [ "ssh-ed25519 ..." ];
};
```

### Change Password Later

On the system:
```bash
sudo passwd myuser
```

Or regenerate hash and update `users.nix`.

## SSH Keys

### Adding SSH Keys

```nix
myuser = {
  opensshKeys = [
    "ssh-ed25519 AAAAC3Nza... user@laptop"
    "ssh-rsa AAAAB3NzaC1... user@desktop"
  ];
};
```

### Generate SSH Key

```bash
ssh-keygen -t ed25519 -C "user@hostname"
cat ~/.ssh/id_ed25519.pub  # Copy this
```

### Multiple Keys

Users can have multiple SSH keys for different machines:

```nix
opensshKeys = [
  "ssh-ed25519 ... user@work-laptop"
  "ssh-ed25519 ... user@home-desktop"  
  "ssh-ed25519 ... user@tablet"
];
```

## Examples

### Basic User

```nix
student = {
  description = "Student Account";
  extraGroups = [ "networkmanager" ];
  shell = pkgs.bash;
  hashedPassword = "$6$...";
};
```

### Admin User with SSH

```nix
admin = {
  description = "System Administrator";
  extraGroups = [ "wheel" "networkmanager" "docker" ];
  shell = pkgs.zsh;
  hashedPassword = "$6$...";
  opensshKeys = [
    "ssh-ed25519 AAAA... admin@laptop"
  ];
};
```

### User with External Dotfiles

```nix
developer = {
  description = "Developer";
  extraGroups = [ "wheel" "docker" ];
  shell = pkgs.zsh;
  hashedPassword = "$6$...";
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123def456...";
  };
};
```

### WSL User

```nix
wsl-user = {
  description = "WSL User";
  extraGroups = [ "wheel" ];
  shell = pkgs.zsh;
  hashedPassword = "$6$...";
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";
  };
};
```

Enable in inventory.nix:
```nix
nix-wsl = {
  devices."my-wsl".ugaif.forUser = "wsl-user";
};
```

### User Without System Themes

For users who want complete control over their shell/editor:

```nix
poweruser = {
  description = "Power User";
  extraGroups = [ "wheel" ];
  shell = pkgs.zsh;
  hashedPassword = "$6$...";
  useZshTheme = false;      # Don't apply system theme
  useNvimPlugins = false;   # Don't apply system nvim config
  home = builtins.fetchGit {
    url = "https://github.com/username/custom-dotfiles";
    rev = "abc123...";
  };
};
```

## Theme Integration

### System Zsh Theme

When `useZshTheme = true` (default), the system applies:
- Oh My Posh with custom theme
- History substring search
- Vi mode (for non-root users)
- Zsh plugins (zplug)

Disable if you want full control in your dotfiles.

### System Neovim Config

When `useNvimPlugins = true` (default), the system applies:
- LazyVim distribution
- TreeSitter parsers
- Language servers

Disable if you want to configure Neovim yourself.

## Troubleshooting

### User Can't Login

**Check if enabled on host:**
```bash
nix eval .#nixosConfigurations.nix-laptop1.config.ugaif.users.myuser.enable
```

**Check if user exists:**
```bash
# On the system
id myuser
```

### SSH Key Not Working

**Check key in configuration:**
```bash
nix eval .#nixosConfigurations.nix-laptop1.config.users.users.myuser.openssh.authorizedKeys.keys
```

**Verify key format:**
- Should start with `ssh-ed25519`, `ssh-rsa`, or `ssh-dss`
- Should be all on one line
- Should end with comment (optional)

### External Config Not Loading

**Check repository access:**
```bash
git ls-remote https://github.com/username/dotfiles
```

**Verify structure:**
- Must have `home.nix` at repository root
- `nixos.nix` is optional
- Check file permissions

**Test with local path first:**
```nix
home = /path/to/local/dotfiles;
```

## See Also

- [docs/EXTERNAL_MODULES.md](EXTERNAL_MODULES.md) - External module guide
- [docs/INVENTORY.md](INVENTORY.md) - Host configuration
- [docs/NAMESPACE.md](NAMESPACE.md) - Configuration options
- [templates/user/](../templates/user/) - User module template
- [README.md](../README.md) - Main documentation

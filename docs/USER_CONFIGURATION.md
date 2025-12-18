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
  # Option 1: Inline definition
  myuser = {
    description = "My Full Name";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$...";  # Generate with: mkpasswd -m sha-512
    opensshKeys = [
      "ssh-ed25519 AAAA... user@machine"
    ];
  };
  
  # Option 2: External configuration (recommended for personalization)
  myuser.external = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";  # Pin to specific commit
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
  
  # === External Configuration ===
  external = builtins.fetchGit { ... };   # External user module (see below)
  
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
  # Basic options can be set here OR in the external module's user.nix
  description = "My Name";
  extraGroups = [ "wheel" ];
  hashedPassword = "$6$...";
  
  # Point to external configuration repository
  external = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";  # Pin to specific commit
  };
};
```

### External Repository Structure

```
dotfiles/
├── user.nix     # Required: User options AND home-manager config
├── nixos.nix    # Optional: System-level configuration
└── config/      # Optional: Your dotfiles
    ├── bashrc
    ├── vimrc
    └── ...
```

**At least `user.nix` should be present for a functional user module.**

**user.nix (required):**
```nix
{ inputs, ... }:
{ config, lib, pkgs, osConfig ? null, ... }:
{
  # ========== User Account Configuration ==========
  # These options define the user account itself
  ugaif.users.myuser = {
    description = "My Full Name";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    hashedPassword = "!";
    opensshKeys = [
      "ssh-ed25519 AAAA... user@host"
    ];
    useZshTheme = true;
    useNvimPlugins = true;
  };

  # ========== Home Manager Configuration ==========
  # User environment, packages, and dotfiles
  
  home.packages = with pkgs; [
    vim
    ripgrep
  ] ++ lib.optional (osConfig.ugaif.sw.type or null == "desktop") firefox;

  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
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

**In user.nix:**
- `inputs` - Flake inputs (nixpkgs, home-manager, etc.)
- `config` - Configuration (NixOS or home-manager depending on import context)
- `lib` - Nixpkgs library functions
- `pkgs` - Package set
- `osConfig` - (home-manager context only) OS-level configuration

### How External Modules Are Loaded

The `user.nix` module serves a dual purpose and is imported in **two contexts**:

1. **NixOS Module Context (User Options)**: The module is imported as a NixOS module where `ugaif.users.<username>` options are read to define the user account (description, shell, groups, SSH keys, etc.). These options override any defaults set in `users.nix`.

2. **Home-Manager Context**: The same module is imported into home-manager where `home.*`, `programs.*`, and `services.*` options configure the user's environment, packages, and dotfiles.

**Key insight:** A single `user.nix` file contains both account configuration AND home environment configuration. The system automatically imports it in the appropriate contexts.

**Example:** The user account options (like `shell`, `extraGroups`) are read during NixOS evaluation, while home-manager options (like `home.packages`, `programs.git`) are used when building the user's home environment.

**In nixos.nix:**
- `inputs` - Flake inputs
- `config` - NixOS configuration
- `lib` - Nixpkgs library functions
- `pkgs` - Package set

### Alternative Configuration Methods

**Local path (for testing):**
```nix
external = /home/username/dev/dotfiles;
```

**Note:** User options can be set in users.nix OR in the external module's user.nix file. For custom packages and environment configuration without external modules, create a local module and reference it with `extraImports`.

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

### User with External Configuration

```nix
developer = {
  description = "Developer";
  extraGroups = [ "wheel" "docker" ];
  shell = pkgs.zsh;
  hashedPassword = "$6$...";
  external = builtins.fetchGit {
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
  external = builtins.fetchGit {
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
  external = builtins.fetchGit {
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
- Must have `user.nix` at repository root
- `nixos.nix` is optional
- Check file permissions

**Test with local path first:**
```nix
external = /path/to/local/dotfiles;
```

## See Also

- [EXTERNAL_MODULES.md](EXTERNAL_MODULES.md) - External module guide
- [INVENTORY.md](INVENTORY.md) - Host configuration guide
- [NAMESPACE.md](NAMESPACE.md) - Configuration options reference
- [templates/user/](../templates/user/) - User module template
- [README.md](../README.md) - Main documentation

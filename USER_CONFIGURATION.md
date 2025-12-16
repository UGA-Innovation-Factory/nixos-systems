# External User Configuration

This document explains how to use external modules for user configuration in nixos-systems.

## Overview

Users can now maintain their home-manager configurations in separate Git repositories and reference them from `users.nix` using `builtins.fetchGit`, similar to how external system configurations work.

## Changes from Previous System

### Before (Flakes)
```nix
hdh20267 = {
  description = "Hunter Halloran";
  flakeUrl = "github:hdh20267/dotfiles";
};
```

### After (Modules with fetchGit)
```nix
hdh20267 = {
  description = "Hunter Halloran";
  home = builtins.fetchGit {
    url = "https://github.com/hdh20267/dotfiles";
    rev = "abc123...";
  };
};
```

## Configuration Methods

### 1. External Repository (fetchGit)

```nix
myuser = {
  description = "My Name";
  extraGroups = [ "wheel" "networkmanager" ];
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "commit-hash";  # For reproducibility
    ref = "main";         # Optional branch
  };
};
```

### 2. Local Path (for testing)

```nix
myuser = {
  description = "My Name";
  home = /home/username/dev/dotfiles;
};
```

### 3. Inline Configuration

```nix
myuser = {
  description = "My Name";
  home = {
    home.packages = with pkgs; [ vim git ];
    programs.git = {
      enable = true;
      userName = "My Name";
    };
  };
};
```

### 4. No External Config (legacy)

```nix
myuser = {
  description = "My Name";
  homePackages = [ pkgs.vim ];
  # home = null;  # Default
};
```

## External Repository Structure

When using `fetchGit` or a path, the repository must contain:

### Required: home.nix

```nix
{ inputs, ... }:

{ config, lib, pkgs, osConfig, ... }:

{
  # Home-manager configuration
  home.packages = with pkgs; [ ... ];
  programs.git = { ... };
}
```

### Optional: nixos.nix

```nix
{ inputs, ... }:

{ config, lib, pkgs, ... }:

{
  # System-level configuration (if needed)
  users.users.myuser.extraGroups = [ "docker" ];
}
```

## Integration with System

External user modules:

1. **Receive inputs**: Same flake inputs as nixos-systems (nixpkgs, home-manager, etc.)
2. **Access osConfig**: Can read system configuration via `osConfig` parameter
3. **Merged with system settings**: Combined with inventory.nix user settings
4. **System themes applied**: Zsh/nvim themes from system if enabled

### Module Loading Order

For home-manager configuration:
1. External module (`home.nix`)
2. System theme module (if `useZshTheme = true`)
3. System nvim config (if `useNvimPlugins = true`)

For NixOS configuration:
1. User's NixOS module (`nixos.nix`, if exists)
2. All other system modules

## Available Parameters

In `home.nix`, you receive:
- `inputs` - Flake inputs (nixpkgs, home-manager, etc.)
- `config` - Home-manager configuration
- `lib` - Nixpkgs library functions
- `pkgs` - Package set
- `osConfig` - OS-level configuration (readonly)

In `nixos.nix`, you receive:
- `inputs` - Flake inputs
- `config` - NixOS configuration
- `lib` - Nixpkgs library functions
- `pkgs` - Package set

## User Options in users.nix

When defining a user with external config:

```nix
username = {
  # Required
  description = "Full Name";
  
  # External configuration
  home = builtins.fetchGit { ... };
  
  # System settings (still configured here)
  extraGroups = [ "wheel" ];
  hashedPassword = "$6$...";
  opensshKeys = [ "ssh-ed25519 ..." ];
  shell = pkgs.zsh;
  
  # Control system integration
  useZshTheme = true;      # Apply system zsh theme
  useNvimPlugins = true;   # Apply system nvim config
  
  # Legacy options (ignored if home is set)
  homePackages = [ ];      # Use home.packages in home.nix instead
  extraImports = [ ];      # Use imports in home.nix instead
};
```

## Examples

### Minimal Dotfiles Repository

```
my-dotfiles/
├── home.nix
└── README.md
```

**home.nix:**
```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [ vim git htop ];
  
  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
  };
}
```

### With Dotfiles

```
my-dotfiles/
├── home.nix
├── nixos.nix
├── dotfiles/
│   ├── bashrc
│   └── vimrc
└── README.md
```

**home.nix:**
```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
  home.file.".bashrc".source = ./dotfiles/bashrc;
  home.file.".vimrc".source = ./dotfiles/vimrc;
  
  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
  };
}
```

### With System Configuration

**nixos.nix:**
```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
  # Add user to docker group
  users.users.myusername.extraGroups = [ "docker" ];
  
  # Install system-level packages
  environment.systemPackages = [ pkgs.docker ];
}
```

## Migration Guide

### From flakeUrl to home

1. **Update users.nix:**
   ```diff
   - flakeUrl = "github:user/dotfiles";
   + home = builtins.fetchGit {
   +   url = "https://github.com/user/dotfiles";
   +   rev = "latest-commit-hash";
   + };
   ```

2. **Update your dotfiles repository:**
   - Rename or ensure you have `home.nix` (not `flake.nix`)
   - Change module signature from flake to simple module:
     ```diff
     - { inputs, outputs, ... }:
     + { inputs, ... }:
     { config, lib, pkgs, ... }:
     ```

3. **Optional: Add nixos.nix** for system-level config

4. **Test locally first:**
   ```nix
   home = /path/to/local/dotfiles;
   ```

5. **Deploy:**
   ```bash
   nix flake check
   ./deploy hostname
   ```

## Benefits

- **No Flakes Required**: Simpler for users unfamiliar with flakes
- **Explicit Versioning**: Pin to specific commits with `rev`
- **Faster Evaluation**: No flake evaluation overhead
- **Local Testing**: Easy to test with local paths
- **Flexibility**: Supports Git, paths, or inline configs
- **Reproducibility**: Commit hashes ensure exact versions

## Templates

See `/home/engr-ugaif/user-config-template/` for templates and detailed examples.

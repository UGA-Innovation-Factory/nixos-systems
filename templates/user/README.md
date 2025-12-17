# User Configuration Template

This directory contains templates for creating external user configuration modules that can be referenced from the main `nixos-systems/users.nix` file.

## Overview

External user modules allow users to maintain their personal configurations (dotfiles, packages, settings) in separate Git repositories and reference them from the main `nixos-systems` repository using `builtins.fetchGit`.

## Structure

```
user-dotfiles-repo/
├── user.nix          # Optional: User options AND home-manager configuration
├── nixos.nix         # Optional: System-level NixOS configuration
├── README.md         # Documentation
└── dotfiles/         # Optional: Dotfiles to symlink
```

**Note:** Both `.nix` files are optional, but at least one should be present for the module to be useful.

## Usage

### 1. Create Your User Configuration Repository

Copy the templates from this directory to your own Git repository:
- `home.nix` - Required for home-manager configuration
- `nixos.nix` - Optional for system-level configuration

### 2. Reference It in users.nix

```nix
{
  ugaif.users = {
    myusername = {
      # Option 1: Set user options in users.nix
      description = "My Name";
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
      
      # Option 2: Or let the external module's user.nix set these options
      
      # Reference external dotfiles module
      external = builtins.fetchGit {
        url = "https://github.com/username/dotfiles";
        rev = "abc123def456...";  # Full commit hash for reproducibility
        ref = "main";              # Optional: branch/tag name
      };
      
      # Or use local path for testing
      # external = /path/to/local/dotfiles;
      # };
    };
  };
}
```

### 3. Enable on Systems

Enable the user in `inventory.nix`:

```nix
{
  "my-system" = {
    devices = {
      "hostname" = {
        ugaif.users.myusername.enable = true;
      };
    };
  };
}
```

## File Descriptions

### user.nix (Optional)

This file serves dual purpose:
1. Sets `ugaif.users.<username>` options (description, shell, extraGroups, etc.)
2. Provides home-manager configuration (programs.*, home.*, services.*)

**How it works:**
- The `ugaif.users.<username>` options are extracted and loaded as **data** during module evaluation
- These options override any defaults set in `users.nix` (which uses `lib.mkDefault`)
- The home-manager options (`home.*`, `programs.*`, etc.) are imported as a module for home-manager
- External module options take precedence over `users.nix` base configuration

The same file is imported in two contexts:
- As a NixOS module to read ugaif.users options
- As a home-manager module for home.*, programs.*, services.*, etc.

Simply include both types of options in the same file.

**Receives:**
- `inputs` - Flake inputs (nixpkgs, home-manager, etc.)
- `config` - Config (NixOS or home-manager depending on context)
- `lib` - Nixpkgs library
- `pkgs` - Nixpkgs package set
- `osConfig` - (home-manager context only) OS-level configuration

**Example:** See `user.nix` template

### nixos.nix (Optional)

This file contains system-level NixOS configuration. Only needed for:
- System services related to the user
- System packages requiring root
- Special permissions or system settings

**Receives:**
- `inputs` - Flake inputs (nixpkgs, home-manager, etc.)
- `config` - NixOS config
- `lib` - Nixpkgs library
- `pkgs` - Nixpkgs package set

## Examples

### Minimal user.nix

```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:

{
  # User account options (imported as NixOS module)
  ugaif.users.myuser = {
    description = "My Name";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Home-manager configuration (imported into home-manager)
  home.packages = with pkgs; [
    vim
    git
    htop
  ];

  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
  };
}
```

### With Dotfiles

```nix
{ inputs, ... }:
{ config, lib, pkgs, ... }:

{
  ugaif.users.myuser = {
    description = "My Name";
    shell = pkgs.zsh;
  };

  home.packages = with pkgs; [ ripgrep fd bat ];

  # Symlink dotfiles
  home.file.".bashrc".source = ./dotfiles/bashrc;
  home.file.".vimrc".source = ./dotfiles/vimrc;
  
  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
  };
}
```

### With System Configuration (nixos.nix)

```nix
{ inputs, ... }:

{ config, lib, pkgs, ... }:

{
  # Add user to docker group
  users.users.myusername.extraGroups = [ "docker" ];
  
  # Install system package
  environment.systemPackages = [ pkgs.docker ];
}
```

## Integration Features

External user modules:
- Receive the same flake inputs as nixos-systems
- Can set user options via user.nix (description, shell, home-manager, etc.)
- Optionally provide system-level configuration (nixos.nix)
- System zsh theme applied if `useZshTheme = true` (default)
- System nvim config applied if `useNvimPlugins = true` (default)
- Settings from user.nix override base users.nix definitions

## Development Workflow

1. Create your user config repository with `user.nix` and/or `nixos.nix`
2. Set user options in user.nix OR in the main users.nix
3. Test locally: `external = /path/to/local/repo;`
4. Build: `nix build .#nixosConfigurations.hostname.config.system.build.toplevel`
5. Commit and push changes
6. Update users.nix with commit hash
7. Deploy to systems

## Benefits

- **Personal Ownership**: Users maintain their own configs
- **Version Control**: Track dotfile changes over time
- **Portability**: Use same config across multiple machines
- **Reproducibility**: Pin to specific commits
- **Privacy**: Use private repositories for personal settings
- **Separation**: Keep personal configs separate from system configs

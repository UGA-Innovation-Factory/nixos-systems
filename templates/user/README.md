# User Configuration Template

This directory contains templates for creating external user configuration modules that can be referenced from the main `nixos-systems/users.nix` file.

## Overview

External user modules allow users to maintain their personal configurations (dotfiles, packages, settings) in separate Git repositories and reference them from the main `nixos-systems` repository using `builtins.fetchGit`.

## Structure

```
user-dotfiles-repo/
├── home.nix          # Required: Home-manager configuration
├── nixos.nix         # Optional: System-level NixOS configuration
├── README.md         # Documentation
└── dotfiles/         # Optional: Dotfiles to symlink
```

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
      description = "My Name";
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
      
      # Option 1: External module from Git
      home = builtins.fetchGit {
        url = "https://github.com/username/dotfiles";
        rev = "abc123def456...";  # Full commit hash for reproducibility
        ref = "main";              # Optional: branch/tag name
      };
      
      # Option 2: Local path for testing
      # home = /path/to/local/dotfiles;
      
      # Option 3: Inline configuration
      # home = {
      #   home.packages = [ pkgs.vim ];
      #   programs.git.enable = true;
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
        extraUsers = [ "myusername" ];
      };
    };
  };
}
```

## File Descriptions

### home.nix (Required)

This file contains your home-manager configuration. It must be a valid NixOS module that accepts `{ inputs, ... }` and returns a home-manager configuration.

**Must export:**
- Home-manager options (programs.*, home.packages, etc.)

**Receives:**
- `inputs` - Flake inputs (nixpkgs, home-manager, etc.)
- `config` - Home-manager config
- `pkgs` - Nixpkgs package set
- `osConfig` - Access to OS-level configuration

### nixos.nix (Optional)

This file contains system-level NixOS configuration. Only needed for:
- System services related to the user
- System packages requiring root
- Special permissions or system settings

## Examples

### Minimal home.nix

```nix
{ inputs, ... }:

{ config, lib, pkgs, ... }:

{
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
- Can use all home-manager options
- Optionally provide system-level configuration (nixos.nix)
- System zsh theme applied if `useZshTheme = true` (default)
- System nvim config applied if `useNvimPlugins = true` (default)
- Merged with inventory.nix user settings (groups, shell, etc.)

## Development Workflow

1. Create your user config repository with `home.nix`
2. Test locally: `home = /path/to/local/repo;`
3. Build: `nix build .#nixosConfigurations.hostname.config.system.build.toplevel`
4. Commit and push changes
5. Update users.nix with commit hash
6. Deploy to systems

## Benefits

- **Personal Ownership**: Users maintain their own configs
- **Version Control**: Track dotfile changes over time
- **Portability**: Use same config across multiple machines
- **Reproducibility**: Pin to specific commits
- **Privacy**: Use private repositories for personal settings
- **Separation**: Keep personal configs separate from system configs

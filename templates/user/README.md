# User Configuration Template

This directory contains templates for creating external user configuration modules that can be referenced from the main `nixos-systems/users.nix` file.

## Overview

External user modules allow users to maintain their personal configurations (dotfiles, packages, settings) in separate Git repositories and reference them from the main `nixos-systems` repository using `builtins.fetchGit`.

## Structure

```
user-dotfiles-repo/
├── user.nix          # Required: User options AND home-manager configuration
├── nixos.nix         # Optional: System-level NixOS configuration
├── README.md         # Documentation
└── config/           # Optional: Dotfiles to symlink
    ├── bashrc
    └── vimrc
```

**Note:** The `user.nix` file is required for a functional user module. It should contain both `ugaif.users.<username>` options and home-manager configuration.

## Usage

### 1. Create Your User Configuration Repository

Copy the templates from this directory to your own Git repository:
- `user.nix` - Required: Contains both user account options and home-manager configuration
- `nixos.nix` - Optional: System-level NixOS configuration (e.g., system services, extra groups)

### 2. Reference It in users.nix

```nix
{
  ugaif.users = {
    # Option 1: Define inline (without external module)
    inlineuser = {
      description = "My Name";
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
      hashedPassword = "$6$...";
    };
    
    # Option 2: Use external module (recommended for personal configs)
    # The external user.nix will set ugaif.users.myusername options
    myusername.external = builtins.fetchGit {
      url = "https://github.com/username/dotfiles";
      rev = "abc123def456...";  # Full commit hash for reproducibility
      ref = "main";              # Optional: branch/tag name
    };
    
    # Or use local path for testing
    # myusername.external = /path/to/local/dotfiles;
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

### user.nix (Required)

This file serves a dual purpose and is imported in **two contexts**:

1. **NixOS Module Context**: Imported to read `ugaif.users.<username>` options that define the user account (description, shell, groups, SSH keys, etc.)
2. **Home-Manager Context**: Imported to configure the user environment with `home.*`, `programs.*`, and `services.*` options

**How it works:**
- The same file is evaluated twice in different contexts
- User account options (`ugaif.users.<username>`) are read during NixOS evaluation
- Home-manager options are used when building the user's environment
- External module options override any defaults set in `users.nix`
- You can conditionally include packages/config based on system type using `osConfig`

**Receives:**
- `inputs` - Flake inputs (nixpkgs, home-manager, etc.)
- `config` - Configuration (NixOS or home-manager depending on context)
- `lib` - Nixpkgs library functions
- `pkgs` - Nixpkgs package set
- `osConfig` - (home-manager context only) Read-only access to OS configuration

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
{ config, lib, pkgs, osConfig ? null, ... }:
{
  # User account options
  ugaif.users.myuser = {
    description = "My Name";
    shell = pkgs.zsh;
    hashedPassword = "!";
    extraGroups = [ "wheel" "networkmanager" ];
    opensshKeys = [ "ssh-ed25519 AAAA... user@host" ];
    useZshTheme = true;
    useNvimPlugins = true;
  };

  # Home-manager configuration
  home.packages = with pkgs; [
    vim
    git
    htop
  ];

  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
    extraConfig.init.defaultBranch = "main";
  };
}
```

### With Dotfiles

```nix
{ inputs, ... }:
{ config, lib, pkgs, osConfig ? null, ... }:
{
  ugaif.users.myuser = {
    description = "My Name";
    shell = pkgs.zsh;
    hashedPassword = "!";
    extraGroups = [ "wheel" ];
    opensshKeys = [ "ssh-ed25519 AAAA..." ];
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    bat
  ] ++ lib.optional (osConfig.ugaif.sw.type or null == "desktop") firefox;

  # Symlink dotfiles
  home.file.".bashrc".source = ./config/bashrc;
  home.file.".vimrc".source = ./config/vimrc;
  
  programs.git = {
    enable = true;
    userName = "My Name";
    userEmail = "me@example.com";
    extraConfig.init.defaultBranch = "main";
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
- Define both user account options AND home-manager config in user.nix
- Single file is imported in two contexts (NixOS module + home-manager module)
- Can access OS configuration via `osConfig` parameter in home-manager context
- Optionally provide system-level configuration (nixos.nix)
- System zsh theme applied if `useZshTheme = true` (default)
- System nvim config applied if `useNvimPlugins = true` (default)
- Settings from external user.nix override base users.nix definitions

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

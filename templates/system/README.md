# External System Module Template

This directory contains a template for creating external system configuration modules that can be referenced from the main `nixos-systems` repository.

## Overview

External modules allow you to maintain system configurations in separate Git repositories and reference them from the main `nixos-systems/inventory.nix` file using `builtins.fetchGit` or `builtins.fetchTarball`.

## Usage

### 1. Create Your Module Repository

Copy `default.nix` from this template to your own Git repository. Customize it with your system configuration.

### 2. Reference It in inventory.nix

```nix
{
  "my-system-type" = {
    devices = {
      "hostname" = builtins.fetchGit {
        url = "https://github.com/your-org/your-config-repo";
        rev = "abc123def456...";  # Full commit hash for reproducibility
        ref = "main";              # Optional: branch/tag name
      };
    };
  };
}
```

### 3. Module Structure

Your `default.nix` must:
- Accept `{ inputs, ... }` as parameters (you'll receive the same flake inputs)
- Return a valid NixOS module with `{ config, lib, pkgs, ... }: { ... }`
- Export configuration under the `config` attribute

## Examples

### Simple Configuration Module

```nix
{ inputs, ... }:

{ config, lib, pkgs, ... }:

{
  config = {
    time.timeZone = "America/New_York";
    
    environment.systemPackages = with pkgs; [
      vim
      git
      htop
    ];
    
    services.openssh.enable = true;
  };
}
```

### Advanced Module with Options

```nix
{ inputs, ... }:

{ config, lib, pkgs, ... }:

{
  options.myorg.databaseUrl = lib.mkOption {
    type = lib.types.str;
    description = "Database connection URL";
  };

  config = {
    # Use the option
    services.postgresql = {
      enable = true;
      # ... configuration using config.myorg.databaseUrl
    };
  };
}
```

## Benefits

- **Separation of Concerns**: Keep specialized configurations in dedicated repositories
- **Reusability**: Share configurations across multiple NixOS fleets
- **Version Control**: Pin to specific commits for reproducibility
- **Team Ownership**: Different teams can maintain their own config repos
- **Security**: Private repositories for sensitive configurations

## Integration with nixos-systems

External modules are automatically integrated into the nixos-systems build:
- They receive the same flake inputs (nixpkgs, home-manager, etc.)
- They can use ugaif.* options if defined in the host type
- They are merged with local overrides and base configuration
- They work with all build methods (ISO, LXC, Proxmox, etc.)

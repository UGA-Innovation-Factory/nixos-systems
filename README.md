# UGA Innovation Factory - NixOS Systems

This repository contains the NixOS configuration for the Innovation Factory's fleet of laptops, desktops, and surface tablets.

## Repository Structure

- **`flake.nix`**: The entry point for the configuration.
- **`inventory.nix`**: Defines the fleet inventory (host types, counts, and device-specific overrides).
- **`users.nix`**: Defines user accounts, passwords, and package sets.
- **`hosts/`**: Contains the logic for generating host configurations and hardware-specific types.
- **`sw/`**: Software modules (Desktop, Kiosk, Python, Neovim, etc.).

## Quick Start

### Updating the System

The system includes a utility script `update-system` that handles rebuilding and switching configurations. It automatically detects if it is running on a Surface tablet and offloads the build to a more powerful host if necessary.

To apply changes to the current system:

```bash
update-system
```

This command pulls the latest configuration from GitHub and rebuilds the system.

If your configuration uses external flakes (e.g., via `flakeUrl`), you may need to allow impure evaluation:

```bash
update-system --impure
```

### Manual Rebuilds

If you need to rebuild manually or target a specific host:

```bash
# Local build
sudo nixos-rebuild switch --flake .

# Build for a specific host
sudo nixos-rebuild switch --flake .#nix-laptop1
```

### Updating Flake Inputs

To update the lockfile (nixpkgs, home-manager versions, etc.):

```bash
nix flake update
```

## Configuration Guide

### Adding a New User

1.  Open `users.nix`.
2.  Add a new entry to `modules.users.accounts`.
3.  Generate a hashed password using `mkpasswd -m sha-512` (requires `whois` package or similar).
4.  Commit and push.

### Assigning Users to Hosts

By default, only `root` and `engr-ugaif` are enabled. To enable a specific student user on a specific device:

1.  Open `inventory.nix`.
2.  Locate the host type (e.g., `nix-laptop`).
3.  Add or update the `devices` section for the specific index:

```nix
nix-laptop = {
  count = 2;
  devices = {
    "1" = { extraUsers = [ "student_username" ]; };
  };
};
```

### Using External Flakes for User Configuration

Users can manage their own Home Manager configuration in a separate flake repository. To use this:

1.  Open `users.nix`.
2.  In the user's configuration block, set the `flakeUrl` option:

```nix
hdh20267 = {
  # ... other settings ...
  flakeUrl = "github:hdh20267/dotfiles";
};
```

The external flake must provide a `homeManagerModules.default` output. Note that using this feature may require running `update-system --impure` if the flake is not locked in the system's `flake.lock`.

### Using External Flakes for System Configuration

You can also override the system-level configuration for a specific host using an external flake. This is useful for adding system services (like Docker), changing boot parameters, or installing system-wide packages that are not in the standard image.

1.  Open `inventory.nix`.
2.  In the `devices` override for the host, set the `flakeUrl`:

```nix
nix-laptop = {
  count = 2;
  devices = {
    "2" = { 
      flakeUrl = "github:myuser/my-system-config"; 
      # You can still combine this with other overrides
      swapSize = "64G";
    };
  };
};
```

The external flake must provide a `nixosModules.default` output.

## External Flake Templates

If you are creating a new flake to use with `flakeUrl`, use these templates as a starting point.

### Home Manager Flake (for `users.nix`)

Use this for user-specific dotfiles, shell configuration, and user packages.

```nix
{
  description = "My Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager is not strictly required as an input if you only export a module,
    # but it's good practice for standalone testing.
  };

  outputs = { self, nixpkgs, ... }: {
    # This output is what nixos-systems looks for
    homeManagerModules.default = { pkgs, ... }: {
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
}
```

### System Flake (for `inventory.nix`)

Use this for host-specific system services, hardware tweaks, or root-level packages.

```nix
{
  description = "My System Configuration Override";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }: {
    # This output is what nixos-systems looks for
    nixosModules.default = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.docker ];
      
      virtualisation.docker.enable = true;
      
      # Example: Add a custom binary cache
      nix.settings.substituters = [ "https://nix-community.cachix.org" ];
      nix.settings.trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };
  };
}
```

### Adding a New Host

1.  Open `inventory.nix`.
2.  Increment the `count` for the relevant host type.
3.  The new host will be named sequentially (e.g., `nix-laptop3`).

## Development

### Python Environment

The system comes with `pixi` and `uv` for Python project management. It is recommended to use these tools for project-specific environments rather than installing global Python packages.

```bash
pixi init my_project
cd my_project
pixi add pandas numpy
```

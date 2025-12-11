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

### Adding a New User

1.  Open `users.nix`.
2.  Add a new entry to `modules.users.accounts`.
3.  Generate a hashed password using `mkpasswd -m sha-512` (requires `whois` package or similar).
  - Hashed passwords are intended for shared credentials as a minimal layer of safety; do not treat them as secure storage for personal secrets (use per-user secrets managed outside the flake instead).
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

### Customizing the Kiosk URL for Surfaces

Surface tablets run the kiosk configuration and delegate the Chromium launch URL via `sw.kioskUrl`. You can set a per-device URL directly from `inventory.nix` by providing a `modules` override for the device entry:

```nix
nix-surface = {
  count = 3;
  devices = {
    "1" = {
      modules = {
        sw = {
          kioskUrl = "https://ha.factory.uga.edu/surface-1";
        };
      };
    };
  };
};
```

Any other device attributes (filesystem overrides, extra users) can still sit beside `modules`; they are merged into the generated host configuration so you just need to set the `kioskUrl` value you want to use for that Surface.

Users can manage their own configuration (both Home Manager and System-level settings) in a separate flake repository. External flakes run with the same privileges as the primary configuration, so audit any flake before pointing to it and pin to a known-good commit when possible.
To use this:

1.  Open `users.nix`.
2.  In the user's configuration block, set the `flakeUrl` option:

```nix
hdh20267 = {
  # ... other settings ...
  flakeUrl = "github:hdh20267/dotfiles";
};
```

The external flake must provide a `nixosModules.default` output. This module is imported into the system configuration, allowing the user to override their own system settings (like `shell`, `extraGroups`) and define their Home Manager configuration.

You can also opt-out of the default system configurations for Zsh and Neovim if you prefer to manage them entirely yourself:

*   `useZshTheme` (default: `true`): Set to `false` to disable the system-wide Zsh theme and configuration.
*   `useNvimPlugins` (default: `true`): Set to `false` to disable the system-wide Neovim plugins and configuration.

### Using External Flakes for System Configuration

You can also override the system-level configuration for a specific host using an external flake. This is useful for adding system services (like Docker), changing boot parameters, installing system-wide packages, or even overriding hardware settings (like swap size) without modifying `inventory.nix`.

1.  Open `inventory.nix`.
2.  In the `devices` override for the host, set the `flakeUrl`:

```nix
nix-laptop = {
  count = 2;
  devices = {
    "2" = { 
      flakeUrl = "github:myuser/my-system-config"; 
    };
  };
};
```

The external flake must provide a `nixosModules.default` output. Any configuration defined in that module will be merged with the host's configuration, so treat these flakes as privileged code and audit them before importing.

## External Flake Templates

If you are creating a new flake to use with `flakeUrl`, use these templates as a starting point.

### User Flake (for `users.nix`)

Use this for user-specific dotfiles, shell configuration, and user packages. It can also override system-level user settings.

Note that `inputs` are omitted. This ensures the flake uses the exact same `nixpkgs` version as the main system, preventing version drift and saving disk space.

```nix
{
  description = "My User Configuration";

  # No inputs needed! We use the system's packages.

  outputs = { self }: {
    # This output is what nixos-systems looks for
    nixosModules.default = { pkgs, lib, ... }: {
      
      # 1. Override System-Level User Settings
      modules.users.accounts.hdh20267 = {
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

Use this for host-specific system services, hardware tweaks, or root-level packages.

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
      host.filesystem.swapSize = lib.mkForce "64G";

      # Example: Enable specific users
      modules.users.enabledUsers = [ "myuser" ];
      
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

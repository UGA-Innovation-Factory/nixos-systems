# External Module Support Implementation

## Summary

Modified `nixos-systems` to support external system configurations via Nix modules instead of flakes. Device configurations can now point to URLs using `builtins.fetchGit`, `builtins.fetchTarball`, or local paths.

## Changes Made

### 1. `inventory.nix`
- Added documentation for external module syntax
- Added comprehensive examples showing different fetch methods
- Demonstrated usage: `devices."hostname" = builtins.fetchGit { url = "..."; rev = "..."; }`

### 2. `hosts/default.nix`
- Modified `mkHost` function to accept `externalModulePath` parameter
- Added logic to import and integrate external modules into the module list
- Updated device processing to detect path/derivation types (from fetchGit/fetchTarball)
- External modules are imported with `{ inputs; }` parameter, receiving same flake inputs
- External modules are merged alongside other configuration modules

### 3. `system-module-template/`
- Created `default.nix` template showing proper module structure
- Created `README.md` with usage instructions and examples
- Documented how external modules integrate with nixos-systems

## How It Works

### In inventory.nix:
```nix
{
  "my-type" = {
    devices = {
      # Option 1: Traditional config attrset
      "local-host" = {
        extraUsers = [ "user1" ];
        # ... normal NixOS config
      };
      
      # Option 2: External module from Git
      "remote-host" = builtins.fetchGit {
        url = "https://github.com/org/config";
        rev = "abc123...";
      };
    };
  };
}
```

### Detection Logic:
The system detects if a device value is:
1. A path (`builtins.isPath`)
2. A string starting with `/` (absolute path)
3. A derivation (`lib.isDerivation`)

If any of these are true, it treats it as an external module path.

### Module Import:
External modules are imported as:
```nix
import externalModulePath { inherit inputs; }
```

They receive the same flake inputs and can use all available modules and packages.

### Integration Order:
1. User flake modules (from users.nix)
2. Host type module (from hosts/types/)
3. Config override module
4. Hostname assignment
5. External flake module (if flakeUrl specified in config)
6. External path module (if fetchGit/fetchurl/path detected)

## Benefits

- **Separation**: Keep system configs in separate repos
- **Reusability**: Share configs across multiple deployments
- **Versioning**: Pin to specific commits for reproducibility
- **Flexibility**: Mix external modules with local overrides
- **Compatibility**: Works with all existing build methods (ISO, LXC, Proxmox)

## Testing

All existing configurations continue to work:
```bash
nix flake check  # Passes ✓
nix eval .#nixosConfigurations.nix-desktop1.config.networking.hostName  # Works ✓
```

## Example External Module Repository Structure

```
my-server-config/
├── default.nix          # Main module (required)
├── README.md           # Documentation
└── custom-service.nix  # Additional modules (optional)
```

The `default.nix` must export a NixOS module:
```nix
{ inputs, ... }:

{ config, lib, pkgs, ... }:

{
  config = {
    # Your configuration here
  };
}
```

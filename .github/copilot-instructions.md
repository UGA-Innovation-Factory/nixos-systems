# GitHub Copilot Instructions for nixos-systems

This repository manages NixOS configurations for the UGA Innovation Factory's fleet of devices using Nix flakes and a custom configuration system.

## Repository Overview

This is a **NixOS system configuration repository** that uses:
- **Nix flakes** for dependency management and reproducible builds
- **Custom namespace** (`ugaif.*`) for all Innovation Factory-specific options
- **Inventory-based** host generation from `inventory.nix`
- **External module support** for user and system configurations
- **Multiple hardware types**: desktops, laptops, Surface tablets, LXC containers, WSL

## Code Style and Conventions

### Nix Code Style
- Use the repository's formatter: `nix fmt **/*.nix` (uses `nixfmt-rfc-style`)
- Follow existing indentation (2 spaces)
- Use descriptive variable names
- Add comments for complex logic, especially in host generation
- Preserve existing comment style and documentation

### File Organization
- **`flake.nix`**: Entry point - inputs and outputs only
- **`inventory.nix`**: Fleet definitions - host configurations
- **`users.nix`**: User account definitions
- **`hosts/`**: Host generation logic and hardware types
- **`sw/`**: Software configurations organized by system type
- **`installer/`**: Build artifact generation (ISO, LXC, etc.)
- **`templates/`**: Templates for external configurations

### Naming Conventions
- Module options: Use `ugaif.*` namespace for all custom options
- Hostnames: `{type}{number}` or `{type}-{name}` (e.g., `nix-laptop1`, `nix-surface-alpha`)
- Hardware types: Prefix with `nix-` (e.g., `nix-desktop`, `nix-laptop`)
- Software types: Use descriptive names (`desktop`, `tablet-kiosk`, `headless`)

## Custom Namespace (`ugaif`)

All Innovation Factory-specific options MUST use the `ugaif` namespace:

### Host Options (`ugaif.host.*`)
```nix
ugaif.host = {
  filesystem.device = "/dev/sda";      # Boot disk
  filesystem.swapSize = "32G";         # Swap size
  buildMethods = [ "iso" ];            # Artifact types
  useHostPrefix = true;                # Hostname prefix behavior
  wsl.user = "username";               # WSL default user
};
```

### Software Options (`ugaif.sw.*`)
```nix
ugaif.sw = {
  type = "desktop";                    # System type
  kioskUrl = "https://...";            # Kiosk browser URL
  python.enable = true;                # Python tools (pixi, uv)
  remoteBuild = {
    enable = true;                     # Use remote builders
    hosts = [ "nix-builder" ];         # Build servers
  };
  extraPackages = with pkgs; [ ... ];  # Additional packages
};
```

### User Options (`ugaif.users.*`)
```nix
ugaif.users = {
  accounts = { ... };                  # User definitions
  enabledUsers = [ "root" "engr-ugaif" ]; # Enabled users
};
ugaif.forUser = "username";            # Convenience: enable user + set WSL user
```

## Development Workflow

### Testing Changes
1. **Always run `nix flake check` before committing** to validate all configurations
2. Use `nix flake check --show-trace` for detailed error messages
3. Test specific host builds: `nix build .#nixosConfigurations.{hostname}.config.system.build.toplevel`
4. For local testing: `sudo nixos-rebuild test --flake .`

### Making Changes
1. **Minimal modifications**: Change only what's necessary
2. **Preserve existing functionality**: Don't break working configurations
3. **Test before committing**: Run `nix flake check` to validate all hosts
4. **Update documentation**: Keep README.md and other docs in sync with changes

### Common Tasks

#### Adding a New User
1. Edit `users.nix` to add user definition under `ugaif.users.accounts`
2. Enable user in `inventory.nix` via `ugaif.users.username.enable = true` or use `ugaif.forUser = "username"`
3. Test: `nix flake check`

#### Adding a New Host
1. Edit `inventory.nix` to add device(s) under appropriate type
2. Use `devices = N` for simple count or `devices = { ... }` for custom configs
3. Test: `nix flake check` and build specific host

#### Modifying Software Configuration
1. Edit appropriate file in `sw/` directory based on system type
2. For system-wide changes: modify `sw/{type}/programs.nix`
3. For specific hosts: use `ugaif.sw.extraPackages` in `inventory.nix`
4. Test: `nix flake check`

#### Creating External Modules
1. Use templates: `nix flake init -t github:UGA-Innovation-Factory/nixos-systems#{user|system}`
2. User modules: Provide `home.nix` (required) and `nixos.nix` (optional)
3. System modules: Provide `default.nix` that accepts `{ inputs, ... }`
4. Reference in `inventory.nix` or `users.nix` using `builtins.fetchGit`

## Important Constraints

### What NOT to Do
- **Never** use options outside the `ugaif` namespace for Innovation Factory-specific functionality
- **Never** remove or modify working host configurations unless explicitly requested
- **Never** break existing functionality when adding new features
- **Never** hardcode values that should be configurable
- **Never** add global changes that affect all systems without careful consideration

### What to ALWAYS Do
- **Always** run `nix flake check` before finalizing changes
- **Always** use the `ugaif.*` namespace for custom options
- **Always** preserve existing comment styles and documentation
- **Always** test that configurations build successfully
- **Always** consider impact on existing hosts when making changes
- **Always** use `nix fmt **/*.nix` to format code before committing

## External Module Integration

This repository supports external configurations via Git repositories:

### User Configurations (Dotfiles)
```nix
# In users.nix
myuser = {
  description = "My Name";
  home = builtins.fetchGit {
    url = "https://github.com/username/dotfiles";
    rev = "abc123...";  # Pin to specific commit
  };
};
```

### System Configurations
```nix
# In inventory.nix
nix-lxc = {
  devices."special" = builtins.fetchGit {
    url = "https://github.com/org/server-config";
    rev = "abc123...";
  };
};
```

**Key Points:**
- External modules receive `{ inputs }` parameter with flake inputs
- User modules must provide `home.nix` (home-manager config)
- System modules must provide `default.nix` (NixOS module)
- Always pin to specific commit hash (`rev`) for reproducibility

## Building and Artifacts

### Available Build Commands
```bash
# Check all configurations
nix flake check

# Build installer ISO
nix build .#installer-iso-{hostname}

# Build live ISO
nix build .#iso-{hostname}

# Build LXC container
nix build .#lxc-{hostname}

# Build Proxmox template
nix build .#proxmox-{hostname}

# Show all available outputs
nix flake show
```

### Artifact Types
Set via `ugaif.host.buildMethods`:
- `"iso"` - Installer ISO with auto-install
- `"live-iso"` - Live boot ISO without installer
- `"lxc"` - LXC container tarball
- `"proxmox"` - Proxmox VMA template
- `"ipxe"` - iPXE netboot kernel and initrd

## Troubleshooting

### Common Issues
1. **Build failures**: Run `nix flake check --show-trace` for detailed errors
2. **External modules not loading**: Check URL accessibility and module structure
3. **User not appearing**: Ensure user is enabled for that host
4. **Formatting issues**: Run `nix fmt **/*.nix` to auto-format

### Getting Help
- Review existing documentation: `README.md`, `USER_CONFIGURATION.md`, `EXTERNAL_MODULES.md`
- Check templates in `templates/` directory for examples
- Examine existing configurations in `inventory.nix` and `users.nix`

## Additional Context

### System Types
- **desktop**: Full GNOME desktop environment
- **tablet-kiosk**: Surface tablets with Firefox kiosk browser
- **stateless-kiosk**: Diskless PXE boot kiosks
- **headless**: Servers and containers without GUI

### Hardware Types
- **nix-desktop**: Desktop workstations
- **nix-laptop**: Laptops
- **nix-surface**: Surface Pro tablets
- **nix-lxc**: LXC containers
- **nix-wsl**: WSL (Windows Subsystem for Linux)
- **nix-ephemeral**: Temporary/stateless systems

### Key Dependencies
- NixOS 25.11 (nixpkgs)
- home-manager (user environment)
- disko (disk partitioning)
- nixos-hardware (hardware quirks)
- nixos-generators (ISO/LXC builds)
- nixos-wsl (WSL support)

## Code Review Checklist

When reviewing or generating code:
- [ ] Uses `ugaif.*` namespace for custom options
- [ ] Runs `nix flake check` successfully
- [ ] Follows existing code style and formatting
- [ ] Preserves existing functionality
- [ ] Updates relevant documentation if needed
- [ ] Uses appropriate abstractions (don't repeat logic)
- [ ] Considers impact on all system types
- [ ] Tests artifact builds if modifying build logic
- [ ] Pins external modules to specific commits

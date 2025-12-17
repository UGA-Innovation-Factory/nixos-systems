# Development Guide

This guide covers development workflows for maintaining and extending the nixos-systems repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Testing Changes](#testing-changes)
- [Continuous Integration](#continuous-integration)
- [System Rebuilds](#system-rebuilds)
- [Updating Dependencies](#updating-dependencies)
- [Adding Packages](#adding-packages)
- [Python Development](#python-development)
- [Contributing](#contributing)

## Prerequisites

Install Nix with flakes support:

```bash
# Recommended: Determinate Systems installer (includes flakes)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Alternative: Official installer (requires enabling flakes manually)
sh <(curl -L https://nixos.org/nix/install) --daemon
```

## Testing Changes

Always test configuration changes before committing.

### Validate All Configurations

```bash
# Check all configurations build correctly
nix flake check

# Check with verbose error traces
nix flake check --show-trace
```

### Test Specific Host Build

```bash
# Build a specific host's configuration
nix build .#nixosConfigurations.nix-laptop1.config.system.build.toplevel

# Build installer for specific host
nix build .#installer-iso-nix-laptop1
```

### Test Local Changes

If you're on a NixOS system managed by this flake:

```bash
# Test changes without committing (temporary, doesn't survive reboot)
sudo nixos-rebuild test --flake .

# Apply and switch to new configuration
sudo nixos-rebuild switch --flake .

# Build without switching
sudo nixos-rebuild build --flake .
```

## Continuous Integration

The repository uses GitHub Actions for automated testing and validation.

### CI Workflow

All pull requests and pushes to main trigger the CI pipeline, which includes:

1. **Flake Check** - Validates all NixOS configurations
   - Runs `nix flake check` to ensure all systems build correctly
   - Catches configuration errors early

2. **Format Check** - Ensures code formatting consistency
   - Verifies code is formatted with `nix fmt`
   - Automatically fails if formatting is incorrect

3. **Build Key Configurations** - Tests critical system builds
   - Builds: `nix-builder`, `nix-laptop1`, `nix-desktop1`
   - Ensures core configurations compile successfully

4. **Build Artifacts** - Validates installer and container builds
   - Builds: `lxc-nix-builder`, `installer-iso-nix-laptop1`
   - Verifies deployment artifacts are buildable

### Viewing CI Status

Check the CI status badge at the top of the README or view detailed logs:

```bash
# View workflow status
https://github.com/UGA-Innovation-Factory/nixos-systems/actions
```

### Running CI Checks Locally

Before pushing changes, run the same checks that CI performs:

```bash
# Run all checks
nix flake check --show-trace

# Check formatting
nix fmt
git diff --exit-code  # Should return no changes

# Build specific configuration
nix build .#nixosConfigurations.nix-builder.config.system.build.toplevel

# Build artifacts
nix build .#lxc-nix-builder
```

### CI Caching

The CI workflow uses [Magic Nix Cache](https://github.com/DeterminateSystems/magic-nix-cache-action) to speed up builds by caching Nix store paths between runs. This significantly reduces build times for repeated builds.

### Troubleshooting CI Failures

If CI fails:

1. **Check the error logs** in the GitHub Actions tab
2. **Run the same command locally** to reproduce the issue
3. **Use `--show-trace`** for detailed error information
4. **Verify formatting** with `nix fmt` if format check fails
5. **Check for external dependencies** that might be unavailable

Common CI issues:

- **Flake check fails**: Configuration error in a host definition
- **Format check fails**: Run `nix fmt` locally and commit changes
- **Build fails**: Missing dependency or syntax error in Nix expressions
- **Cache issues**: Usually self-resolving; can retry the workflow

## System Rebuilds

### From Local Directory

```bash
# Rebuild current host from local directory
sudo nixos-rebuild switch --flake .

# Rebuild specific host
sudo nixos-rebuild switch --flake .#nix-laptop1

# Test without switching (temporary, doesn't persist reboot)
sudo nixos-rebuild test --flake .#nix-laptop1

# Build a new generation without activating it
sudo nixos-rebuild build --flake .
```

### From GitHub

```bash
# Rebuild from GitHub main branch
sudo nixos-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems

# Use --impure for external user configurations with fetchGit
sudo nixos-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems --impure

# Rebuild specific host from GitHub
sudo nixos-rebuild switch --flake github:UGA-Innovation-Factory/nixos-systems#nix-laptop1
```

### Boot into Previous Generation

If something breaks:

```bash
# List generations
sudo nixos-rebuild list-generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or select specific generation at boot (GRUB menu)
# Reboot and select "NixOS - Configuration X" from boot menu
```

## Updating Dependencies

### Update All Inputs

```bash
# Update all flake inputs (nixpkgs, home-manager, etc.)
nix flake update

# Review changes
git diff flake.lock

# Test the updates
nix flake check

# Commit if successful
git add flake.lock
git commit -m "Update flake inputs"
git push
```

### Update Specific Input

```bash
# Update only nixpkgs
nix flake lock --update-input nixpkgs

# Update home-manager
nix flake lock --update-input home-manager

# Update multiple specific inputs
nix flake lock --update-input nixpkgs --update-input home-manager
```

### Check for Security Updates

```bash
# After updating, check for known vulnerabilities
nix flake check

# Review nixpkgs changelog
git log HEAD..nixpkgs/nixos-25.11 --oneline | head -20
```

## Adding Packages

### System-Wide Packages by Type

Add packages based on system type:

**Desktop systems:**
```bash
# Edit sw/desktop/programs.nix
vim sw/desktop/programs.nix
```

**Tablet kiosks:**
```bash
# Edit sw/tablet-kiosk/programs.nix
vim sw/tablet-kiosk/programs.nix
```

**Headless systems:**
```bash
# Edit sw/headless/programs.nix
vim sw/headless/programs.nix
```

### Packages for Specific Hosts

Add to `ugaif.sw.extraPackages` in `inventory.nix`:

```nix
nix-laptop = {
  devices = 2;
  overrides = {
    ugaif.sw.extraPackages = with pkgs; [
      vim
      docker
      kubernetes-helm
    ];
  };
};
```

### User-Specific Packages

Add to user's home-manager configuration in `users.nix` or external dotfiles:

```nix
myuser = {
  homePackages = with pkgs; [
    ripgrep
    fd
    bat
  ];
};
```

### Search for Packages

```bash
# Search nixpkgs
nix search nixpkgs firefox
nix search nixpkgs python3

# Show package details
nix eval nixpkgs#firefox.meta.description
```

## Python Development

All systems include modern Python tools: `pixi` and `uv`.

### Pixi (Recommended for Projects)

```bash
# Initialize new project
pixi init my-project
cd my-project

# Add dependencies
pixi add pandas numpy matplotlib jupyter

# Run Python
pixi run python

# Run Jupyter
pixi run jupyter notebook

# Run scripts
pixi run python script.py

# Shell with dependencies
pixi shell
```

### uv (Quick Virtual Environments)

```bash
# Create virtual environment
uv venv

# Activate
source .venv/bin/activate

# Install packages
uv pip install requests pandas

# Freeze requirements
uv pip freeze > requirements.txt

# Install from requirements
uv pip install -r requirements.txt
```

### System Python

Python development tools are configured in `sw/python.nix` and can be controlled via:

```nix
ugaif.sw.python.enable = true;  # Default: enabled
```

## Contributing

### Code Style

- Run formatter before committing: `nix fmt`
- Follow existing code structure and conventions
- Add comments for complex logic
- Use the `ugaif.*` namespace for all custom options

### Testing Workflow

1. Make changes
2. Run formatter: `nix fmt`
3. Test locally: `nix flake check`
4. Test specific builds if needed
5. Commit changes
6. Push to GitHub

```bash
# Full workflow
nix fmt
nix flake check
git add .
git commit -m "Description of changes"
git push
```

### Documentation

Update relevant documentation when making changes:

- `README.md` - Overview and quick start
- `docs/INVENTORY.md` - Inventory configuration
- `docs/NAMESPACE.md` - Configuration options
- `USER_CONFIGURATION.md` - User management
- `EXTERNAL_MODULES.md` - External modules

### Creating Issues

When reporting bugs or requesting features:

1. Check existing issues first
2. Provide clear description
3. Include error messages and traces
4. Specify which hosts are affected
5. Include `flake.lock` info if relevant

## Useful Commands

```bash
# Show all available outputs
nix flake show

# Evaluate specific option
nix eval .#nixosConfigurations.nix-laptop1.config.networking.hostName

# List all hosts
nix eval .#nixosConfigurations --apply builtins.attrNames

# Check flake metadata
nix flake metadata

# Show evaluation trace
nix eval --show-trace .#nixosConfigurations.nix-laptop1

# Build and enter debug shell
nix develop

# Clean up old generations
nix-collect-garbage -d

# Optimize Nix store
nix store optimise
```

## See Also

- [README.md](../README.md) - Main documentation
- [INVENTORY.md](INVENTORY.md) - Host inventory configuration
- [BUILDING.md](BUILDING.md) - Building installation media
- [USER_CONFIGURATION.md](USER_CONFIGURATION.md) - User management

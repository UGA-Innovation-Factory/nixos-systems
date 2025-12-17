# Darwin Configuration Examples

This directory contains example configurations showing how nix-Darwin support would be integrated into the nixos-systems repository.

## Files

- **[darwin-laptop-example.nix](darwin-laptop-example.nix)** - Example Darwin laptop host type
- **[darwin-common-example.nix](darwin-common-example.nix)** - Example Darwin common configuration
- **[darwin-system-example.nix](darwin-system-example.nix)** - Example Darwin system settings (replaces boot.nix)
- **[platform-aware-services-example.nix](platform-aware-services-example.nix)** - Example platform-aware service configuration
- **[inventory-darwin-example.nix](inventory-darwin-example.nix)** - Example inventory with both Linux and Darwin systems

## Purpose

These examples demonstrate:

1. **How Darwin modules differ from NixOS modules**
   - No boot configuration
   - No disk partitioning
   - macOS system defaults instead of systemd settings

2. **Platform-aware configuration**
   - Using `lib.mkIf pkgs.stdenv.isLinux`
   - Using `lib.mkIf pkgs.stdenv.isDarwin`
   - Sharing common configuration

3. **Service translation**
   - systemd services → launchd agents
   - Different timer formats
   - Platform-specific service management

4. **Inventory integration**
   - Mixed Linux/Darwin fleet
   - Platform specification via `system` attribute
   - Consistent configuration patterns

## Key Differences: NixOS vs nix-Darwin

### System Builder
```nix
# NixOS
nixpkgs.lib.nixosSystem { ... }

# Darwin
darwin.lib.darwinSystem { ... }
```

### Boot Configuration
```nix
# NixOS
boot.loader.systemd-boot.enable = true;
boot.kernelParams = [ "quiet" "splash" ];

# Darwin
# No boot configuration - macOS handles this
```

### Services
```nix
# NixOS (systemd)
systemd.services.my-service = {
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
  };
};

# Darwin (launchd)
launchd.agents.my-service = {
  serviceConfig = {
    ProgramArguments = [ "${pkgs.myapp}/bin/myapp" ];
    RunAtLoad = true;
    KeepAlive = true;
  };
};
```

### System Settings
```nix
# NixOS
services.displayManager.sddm.enable = true;
services.desktopManager.plasma6.enable = true;
networking.networkmanager.enable = true;

# Darwin
system.defaults.dock.autohide = true;
system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
# No display manager - uses native macOS
```

### Platform Detection
```nix
# In modules
environment.systemPackages = with pkgs; [
  # Cross-platform
  git htop vim
] ++ lib.optionals stdenv.isLinux [
  # Linux-only
  kdePackages.kate
] ++ lib.optionals stdenv.isDarwin [
  # Darwin-only (rarely needed)
];
```

## Usage

These are **example files only** - they are not meant to be imported directly. They show what the actual implementation would look like after the refactoring described in [DARWIN_SUPPORT_ASSESSMENT.md](../DARWIN_SUPPORT_ASSESSMENT.md).

## Testing

To test Darwin configurations (after implementation):

```bash
# Check Darwin configuration builds
nix build .#darwinConfigurations.darwin-laptop1.system

# Activate on a Mac
darwin-rebuild switch --flake .#darwin-laptop1

# Check all configurations (Linux + Darwin)
nix flake check
```

## References

- **Main Assessment**: [DARWIN_SUPPORT_ASSESSMENT.md](../../DARWIN_SUPPORT_ASSESSMENT.md)
- **Quick Reference**: [DARWIN_QUICK_REFERENCE.md](../DARWIN_QUICK_REFERENCE.md)
- **Architecture Diagram**: [darwin-architecture.md](../darwin-architecture.md)
- **nix-darwin**: https://github.com/LnL7/nix-darwin
- **nix-darwin manual**: https://daiderd.com/nix-darwin/manual/

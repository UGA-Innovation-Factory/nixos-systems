# nix-Darwin Support - Refactoring Assessment

## Executive Summary

This document provides a comprehensive assessment of the work required to extend the `nixos-systems` repository to support nix-Darwin configurations alongside the existing NixOS configurations. The goal is to enable management of macOS systems using the same infrastructure that currently manages Linux systems (desktops, laptops, tablets, containers).

**Estimated Effort: Medium-High Complexity, 2-3 weeks (10-14 days) including development, testing, and iterations**

## Table of Contents

- [Background](#background)
- [Current Architecture Analysis](#current-architecture-analysis)
- [nix-Darwin vs NixOS Differences](#nix-darwin-vs-nixos-differences)
- [Required Changes by Component](#required-changes-by-component)
- [Migration Strategy](#migration-strategy)
- [Testing Requirements](#testing-requirements)
- [Risks and Considerations](#risks-and-considerations)
- [Estimated Effort Breakdown](#estimated-effort-breakdown)

## Background

### What is nix-Darwin?

nix-Darwin is a tool for managing macOS configuration using the Nix package manager. It provides a declarative configuration system similar to NixOS but adapted for macOS. Key differences:

- Uses `darwinSystem` instead of `nixosSystem`
- Different module system (no `boot.*`, `systemd.*` options)
- macOS-specific configuration (launchd instead of systemd, macOS-specific services)
- Different hardware management approach
- Limited filesystem management (no disk partitioning like Disko)

### Current Repository Scope

The repository currently manages:
- Desktop workstations (x86_64-linux)
- Laptops (x86_64-linux)
- Surface tablets (x86_64-linux)
- LXC containers (x86_64-linux)
- WSL instances (x86_64-linux)
- Ephemeral/netboot systems (x86_64-linux)

## Current Architecture Analysis

### Strong Points for Multi-OS Support

1. **Modular Design**: The codebase is already well-structured with:
   - Separate host types (`hosts/types/`)
   - Separate software profiles (`sw/`)
   - Clean separation between hardware and software configuration
   - External module support via fetchGit

2. **Flexible Inventory System**: The `inventory.nix` system with:
   - Type-based configuration
   - Per-device overrides
   - Support for external modules
   - Already supports `system` attribute (e.g., `x86_64-linux`)

3. **Unified User Management**: User configuration through:
   - `users.nix` for account definitions
   - Home Manager integration (works on both NixOS and Darwin)
   - External user configuration support

4. **Abstraction Layer**: The `ugaif.*` namespace provides:
   - Custom options that could be adapted for both platforms
   - Clean separation from OS-specific options

### Areas Requiring Significant Changes

1. **System Builder**: `hosts/default.nix` uses `lib.nixosSystem` exclusively
2. **Boot Configuration**: `hosts/boot.nix` is entirely NixOS-specific (Disko, bootloader)
3. **Service Configuration**: Extensive use of `services.*` and `systemd.*`
4. **Build Artifacts**: ISOs, LXC containers are Linux-specific
5. **Hardware Modules**: All current hardware configs assume x86_64-linux

## nix-Darwin vs NixOS Differences

### Module System Differences

| Aspect | NixOS | nix-Darwin |
|--------|-------|------------|
| System Builder | `nixpkgs.lib.nixosSystem` | `darwin.lib.darwinSystem` |
| Service Manager | systemd | launchd |
| Boot Loader | systemd-boot, GRUB | N/A (macOS boot) |
| Disk Management | Disko, filesystem options | Limited (uses existing macOS partitions) |
| Display Manager | SDDM, GDM, etc. | macOS native |
| Desktop Environment | KDE, GNOME, etc. | macOS native (Aqua) |
| Package Management | NixOS modules | nix-darwin modules + Homebrew integration |
| User Management | users.users.* | users.users.* (similar but different defaults) |

### Configuration Options Mapping

**Available on Both:**
- Home Manager (works identically)
- User account management (mostly compatible)
- Package installation (`environment.systemPackages`)
- Environment variables
- Shell configuration (zsh, bash, fish)
- Network configuration (with differences)

**NixOS-Only (need alternatives or exclusion):**
- `boot.*` - bootloader, kernel, initrd
- `systemd.*` - systemd-specific services
- `disko.*` - disk partitioning
- `services.xserver.*` - X11 server
- `services.displayManager.*` - display managers
- `networking.networkmanager.*` - NetworkManager (Linux-specific)
- `virtualisation.*` - some virtualization options

**Darwin-Only (need to be added):**
- `system.defaults.*` - macOS system defaults
- `launchd.*` - launchd services
- `homebrew.*` - Homebrew integration (optional)
- `system.keyboard.*` - keyboard settings
- `system.trackpad.*` - trackpad settings

## Required Changes by Component

### 1. Flake Inputs (`flake.nix`)

**Current State:**
- Only includes NixOS-related inputs
- Has `forAllSystems` that includes darwin platforms but doesn't use them

**Required Changes:**
```nix
inputs = {
  # Existing inputs...
  
  # ADD: nix-darwin support
  darwin = {
    url = "github:LnL7/nix-darwin";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  
  # Home Manager already compatible with both
};
```

**Effort:** Low (30 minutes)

### 2. Host Generation Logic (`hosts/default.nix`)

**Current State:**
- Hardcoded to use `lib.nixosSystem`
- Assumes Linux-specific modules (common.nix with boot.nix)

**Required Changes:**
1. Add platform detection based on `system` attribute
2. Create conditional system builder:
   ```nix
   mkHost = { hostName, system, hostType, ... }:
     if lib.hasPrefix "darwin" system
     then mkDarwinHost { ... }
     else mkNixOSHost { ... };
   ```
3. Split common.nix into:
   - `common.nix` - truly common configuration (users, home-manager)
   - `linux-common.nix` - Linux-specific (boot, systemd)
   - `darwin-common.nix` - Darwin-specific (launchd, system.defaults)

**Effort:** Medium-High (1-2 days)

**Detailed Steps:**
- Create `mkDarwinHost` function parallel to current `mkHost`
- Import darwin-specific inputs
- Handle module differences (no disko, no boot config on Darwin)
- Ensure user modules work on both platforms
- Test module loading order

### 3. Host Types (`hosts/types/`)

**Current State:**
- All types are Linux-specific (nix-desktop.nix, nix-laptop.nix, etc.)
- Include boot configuration, kernel modules, hardware detection

**Required Changes:**
1. Create new Darwin host types:
   - `darwin-desktop.nix` - iMac, Mac Mini
   - `darwin-laptop.nix` - MacBook Air, MacBook Pro
   - `darwin-studio.nix` - Mac Studio (optional)

2. Each Darwin type should include:
   - Platform specification (`nixpkgs.hostPlatform`)
   - macOS-specific settings (keyboard, trackpad, dock)
   - No boot/kernel configuration
   - Appropriate software profile

**Effort:** Medium (1 day)

**Example Structure for `darwin-laptop.nix`:**
```nix
{ inputs, ... }:
{ config, lib, ... }:
{
  imports = [
    (import ../darwin-common.nix { inherit inputs; })
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";
  
  # macOS-specific settings
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
    };
    NSGlobalDomain = {
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
    };
  };
  
  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "desktop";
}
```

### 4. Boot and Filesystem Configuration (`hosts/boot.nix`)

**Current State:**
- Entirely NixOS-specific
- Includes Disko configuration, bootloader, systemd settings

**Required Changes:**
1. Rename to `hosts/linux-boot.nix`
2. Only import in NixOS systems
3. Create `hosts/darwin-system.nix` for Darwin system defaults

**Effort:** Low (1-2 hours)

### 5. Software Profiles (`sw/`)

**Current State:**
- Mix of platform-agnostic and Linux-specific configuration
- Services configured using systemd

**Required Changes:**

#### `sw/default.nix`
- Add platform detection
- Conditionally load services based on platform
- Keep packages mostly the same (Nix packages work on both)

#### `sw/desktop/`
- **Current:** KDE Plasma, SDDM, systemd services
- **Changes:** 
  - Skip display manager/desktop environment on Darwin (use native macOS)
  - Keep application packages (many work on both platforms)
  - Use launchd for background services on Darwin
  - Handle platform-specific packages (e.g., KDE packages only on Linux)

#### `sw/headless/`
- **Current:** Server services, SSH, Docker
- **Changes:**
  - Most server software works on both
  - Use launchd instead of systemd on Darwin
  - Docker Desktop vs Docker on Linux

**Effort:** Medium-High (1-2 days)

**Platform-Specific Package Handling:**
```nix
environment.systemPackages = with pkgs; [
  # Cross-platform
  git
  htop
  vim
  
  # Linux-only
] ++ lib.optionals pkgs.stdenv.isLinux [
  gnome.nautilus
  kde.plasma-desktop
  
  # Darwin-only
] ++ lib.optionals pkgs.stdenv.isDarwin [
  # macOS-specific CLI tools if needed
];
```

### 6. Service Configuration (`sw/*/services.nix`)

**Current State:**
- All services use systemd (`systemd.services.*`, `systemd.timers.*`)
- Display managers, printing, networking all Linux-specific

**Required Changes:**
1. Create platform-conditional service definitions
2. For Darwin: Convert systemd services to launchd agents
3. Skip Linux-specific services on Darwin (NetworkManager, upower, etc.)

**Example Conversion:**
```nix
# Linux (systemd)
systemd.services.my-service = {
  description = "My Service";
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

**Effort:** Medium (1 day)

### 7. User Configuration (`hosts/user-config.nix`)

**Current State:**
- Uses Home Manager (already cross-platform)
- User account creation is mostly compatible

**Required Changes:**
- Minimal changes needed
- Ensure shell configuration works on both platforms
- Handle platform-specific default packages

**Effort:** Low (2-4 hours)

### 8. Build Artifacts (`installer/artifacts.nix`)

**Current State:**
- Creates ISOs, LXC containers, Proxmox images (all Linux-specific)

**Required Changes:**
1. Skip artifact generation for Darwin hosts (no ISOs for macOS)
2. Optionally add Darwin-specific outputs:
   - System activation scripts
   - Configuration bundles
   - Homebrew bundle files (optional)

**Effort:** Low-Medium (0.5-1 day)

**Note:** Darwin systems typically use:
- `darwin-rebuild switch` command
- No installation media (macOS is pre-installed)
- Possibly nix-darwin installer script

### 9. Inventory Configuration (`inventory.nix`)

**Current State:**
- Already supports `system` attribute
- Type-based organization

**Required Changes:**
1. Add Darwin host examples:
```nix
darwin-laptop = {
  type = "darwin-laptop";
  system = "aarch64-darwin";  # or x86_64-darwin
  devices = 2;
};

darwin-desktop = {
  type = "darwin-desktop";
  system = "aarch64-darwin";
  devices = {
    "studio1".extraUsers = [ "designer" ];
  };
};
```

**Effort:** Minimal (30 minutes - documentation mostly)

### 10. Documentation Updates

**Required Changes:**
1. Update README.md:
   - Add Darwin systems to supported platforms
   - Document Darwin-specific configuration
   - Update examples to include macOS

2. Create DARWIN_SETUP.md:
   - Installation instructions for nix-darwin
   - First-time setup guide
   - Differences from NixOS usage

3. Update USER_CONFIGURATION.md:
   - Note platform compatibility in Home Manager configs
   - Document platform-specific options

**Effort:** Medium (0.5-1 day)

## Migration Strategy

### Phase 1: Foundation (Day 1-2)

1. Add nix-darwin input to flake.nix
2. Create darwin-common.nix
3. Split boot.nix to linux-boot.nix
4. Refactor mkHost to support both platforms
5. Create basic darwin-laptop.nix and darwin-desktop.nix types
6. Test with a single Darwin host

### Phase 2: Software Profiles (Day 2-3)

1. Update sw/default.nix for platform detection
2. Create platform-conditional package lists
3. Update sw/desktop for Darwin compatibility
4. Create launchd equivalents for critical services
5. Test software installation on Darwin

### Phase 3: Integration (Day 3-4)

1. Update inventory.nix with Darwin examples
2. Test user configuration on Darwin
3. Test Home Manager integration
4. Handle external modules on Darwin
5. Update build artifacts logic

### Phase 4: Documentation & Testing (Day 4-5)

1. Write comprehensive documentation
2. Create example configurations
3. Test all Darwin host types
4. Test mixed Linux/Darwin fleet
5. Update templates if needed

### Phase 5: Validation (Day 5+)

1. Test on actual macOS hardware
2. Verify all NixOS configurations still work
3. Test update workflows
4. Document known limitations

## Testing Requirements

### Test Environments Needed

1. **macOS Test System:**
   - Intel Mac (x86_64-darwin) OR
   - Apple Silicon Mac (aarch64-darwin)
   - macOS 12+ recommended

2. **Existing Linux Systems:**
   - Ensure no regressions in NixOS configurations

### Test Cases

#### Platform Detection
- [ ] Correct system builder selected based on `system` attribute
- [ ] Linux hosts build successfully (regression test)
- [ ] Darwin hosts build successfully

#### Host Types
- [ ] darwin-laptop builds and activates
- [ ] darwin-desktop builds and activates
- [ ] All NixOS types still build correctly

#### Software Profiles
- [ ] Desktop profile on Darwin (no KDE/SDDM)
- [ ] Headless profile on Darwin
- [ ] Package installation works
- [ ] Services start correctly (launchd)

#### User Management
- [ ] Users created correctly on Darwin
- [ ] Home Manager configurations apply
- [ ] External user configs work on Darwin
- [ ] Shell configuration (zsh) works

#### Multi-Platform Fleet
- [ ] inventory.nix with mixed Linux/Darwin hosts
- [ ] `nix flake check` passes with both platforms
- [ ] Build artifacts only generated for appropriate platforms

#### External Modules
- [ ] External system modules work on Darwin
- [ ] External user modules work on Darwin
- [ ] Platform-specific external modules can be used

## Risks and Considerations

### Technical Risks

1. **Module Incompatibility:**
   - Some NixOS modules may not have Darwin equivalents
   - May need to create custom Darwin modules
   - **Mitigation:** Start with minimal Darwin configs, expand gradually

2. **Service Translation Complexity:**
   - systemd to launchd conversion is non-trivial
   - Different service management paradigms
   - **Mitigation:** Document which services are available on which platforms

3. **Hardware Abstraction:**
   - Darwin hardware is more standardized (Apple only)
   - Less hardware diversity than Linux
   - **Mitigation:** Create fewer, more general Darwin types

4. **Build System Differences:**
   - No ISOs or installation media for Darwin
   - Different deployment workflow
   - **Mitigation:** Document darwin-rebuild workflow clearly

### Maintenance Considerations

1. **Dual Platform Maintenance:**
   - Changes must be tested on both platforms
   - Platform-specific bugs may arise
   - Need maintainers familiar with both systems

2. **Dependency Management:**
   - nix-darwin follows different release cadence than NixOS
   - May have conflicting nixpkgs requirements
   - **Mitigation:** Use same nixpkgs input for both, test regularly

3. **Documentation Burden:**
   - Need to document both platforms
   - Platform-specific gotchas
   - **Mitigation:** Clear separation of common vs. platform-specific docs

### Operational Risks

1. **Limited Testing:**
   - Fewer Darwin devices in typical lab environment
   - Harder to test at scale
   - **Mitigation:** Start with small Darwin deployment

2. **User Training:**
   - Users need to understand platform differences
   - Different update commands (darwin-rebuild vs nixos-rebuild)
   - **Mitigation:** Comprehensive documentation and examples

## Estimated Effort Breakdown

### Development Time

| Component | Complexity | Time Estimate | Priority |
|-----------|-----------|---------------|----------|
| Flake inputs | Low | 0.5 hours | Critical |
| Host generation refactoring | High | 8-12 hours | Critical |
| Darwin host types | Medium | 6-8 hours | Critical |
| Boot/system config split | Low | 2-3 hours | Critical |
| Software profile updates | High | 8-12 hours | High |
| Service conversion | Medium | 6-8 hours | High |
| User config updates | Low | 2-4 hours | Medium |
| Build artifacts | Medium | 4-6 hours | Medium |
| Inventory examples | Low | 1 hour | Low |
| Documentation | Medium | 4-8 hours | High |

**Total Development Time: 41.5 - 62.5 hours (5-8 development days)**

### Testing Time

| Test Phase | Time Estimate |
|------------|---------------|
| Unit testing (per component) | 8-12 hours |
| Integration testing | 8-12 hours |
| Real hardware testing | 4-8 hours |
| Regression testing (NixOS) | 4-6 hours |

**Total Testing Time: 24-38 hours (3-5 testing days)**

### Total Project Timeline

These estimates include development time, testing time, iterations, and fixes:

**Optimistic:** 8-10 days (1.5-2 weeks) with minimal issues  
**Realistic:** 10-14 days (2-3 weeks) including iterations and fixes  
**Conservative:** 15-20 days (3-4 weeks) with comprehensive testing and documentation

## Alternative Approaches

### Option 1: Separate Repository
Instead of integrating into this repo, create a sister repo `darwin-systems`:
- **Pros:** 
  - Clean separation
  - No risk of breaking existing configs
  - Can be developed independently
- **Cons:** 
  - Code duplication
  - Harder to share common configs
  - Two repos to maintain

### Option 2: Minimal Darwin Support
Only support Darwin for headless/development systems, skip desktop features:
- **Pros:**
  - Much simpler (50% less work)
  - Most useful for developers using MacBooks
- **Cons:**
  - Limited applicability
  - Still need most of the infrastructure changes

### Option 3: Home Manager Only
Only manage Darwin user environments via Home Manager, skip system config:
- **Pros:**
  - Very simple
  - Home Manager already works on Darwin
- **Cons:**
  - Not true system management
  - Doesn't leverage nix-darwin benefits
  - Still need some infrastructure changes

## Recommendation

**Proceed with full nix-Darwin integration** because:

1. **Architecture is Ready:** The codebase is already well-structured for this
2. **Reusable Components:** User management, Home Manager integration already work
3. **Long-term Value:** Unified fleet management is valuable
4. **Manageable Effort:** 2-3 weeks is reasonable for the benefits gained
5. **Low Risk:** Changes can be made incrementally without breaking existing configs

### Suggested Implementation Order

1. **Start Small:** Single darwin-laptop type, minimal services
2. **Test Early:** Validate on real Mac hardware ASAP
3. **Iterate:** Add features based on actual needs
4. **Document:** Write docs as you go, not at the end
5. **Community:** Consider making this a community contribution to both projects

## Conclusion

Adding nix-Darwin support to this repository is a **medium-complexity project** requiring **2-3 weeks of development and testing**. The existing architecture is well-suited for this extension, with clear separation between hardware, software, and user configuration.

The main challenges are:
1. Refactoring the system builder to support both platforms
2. Converting or skipping systemd-based services
3. Creating appropriate Darwin host types
4. Thorough testing on both platforms

The benefits of unified fleet management across Linux and macOS systems justify the development effort, especially for organizations with mixed environments.

### Next Steps

If proceeding with implementation:
1. Set up macOS test environment
2. Add nix-darwin to flake inputs
3. Create proof-of-concept darwin-laptop configuration
4. Test basic system build and activation
5. Incrementally add features following the migration strategy

For questions or discussion, consider:
- Consulting nix-darwin documentation: https://github.com/LnL7/nix-darwin
- Reviewing example nix-darwin configs in the wild
- Engaging with the nix-darwin community for best practices

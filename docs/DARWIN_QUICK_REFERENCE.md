# Darwin Support - Quick Reference Guide

## Overview

This is a quick reference for the work required to add nix-Darwin support to nixos-systems.

**Full Assessment:** See [DARWIN_SUPPORT_ASSESSMENT.md](../DARWIN_SUPPORT_ASSESSMENT.md)  
**Architecture Details:** See [darwin-architecture.md](darwin-architecture.md)

## TL;DR - Effort Summary

| **Overall Effort** | 2-3 weeks (10-14 days) |
| **Complexity** | Medium-High |
| **Risk Level** | Low (well-isolated changes) |
| **Recommended?** | ✅ Yes - Architecture is ready for this |

## What Needs to Change

### Critical Changes (Must Do)

1. **Add nix-darwin input** to `flake.nix` (30 min)
2. **Refactor host generation** in `hosts/default.nix` (1-2 days)
   - Add platform detection
   - Create `mkDarwinHost()` function
   - Split outputs: `nixosConfigurations` + `darwinConfigurations`

3. **Create Darwin host types** (1 day)
   - `hosts/types/darwin-laptop.nix`
   - `hosts/types/darwin-desktop.nix`
   - Import from new `hosts/darwin-common.nix`

4. **Split platform-specific configuration** (2-3 hours)
   - Rename `hosts/common.nix` → `hosts/linux-common.nix`
   - Rename `hosts/boot.nix` → `hosts/linux-boot.nix`
   - Create `hosts/darwin-common.nix`
   - Create `hosts/darwin-system.nix`

5. **Update software profiles** (1-2 days)
   - `sw/default.nix`: Add platform detection
   - `sw/desktop/`: Make services platform-aware (systemd vs launchd)
   - `sw/headless/`: Make services platform-aware

### What Stays the Same

- ✅ User management (`users.nix`) - already cross-platform
- ✅ Home Manager integration - works on both platforms
- ✅ External module support - works for both
- ✅ Inventory system - just add Darwin entries
- ✅ Most application packages - work on both platforms

## Key Technical Differences

| Feature | NixOS | nix-Darwin |
|---------|-------|------------|
| **System Builder** | `nixpkgs.lib.nixosSystem` | `darwin.lib.darwinSystem` |
| **Boot Config** | Yes (bootloader, disko) | No (uses macOS boot) |
| **Services** | systemd | launchd |
| **Desktop** | KDE/GNOME/etc | macOS native (no config needed) |
| **Build Artifacts** | ISOs, LXC, containers | None (or just config bundles) |

## Quick Start Implementation Plan

### Week 1: Foundation
- **Day 1:** Add darwin input, create darwin-common.nix, refactor host generation
- **Day 2:** Create basic darwin-laptop type, test single build
- **Day 3:** Complete darwin types, test builds

### Week 2: Integration
- **Day 4-5:** Update software profiles for platform awareness
- **Day 6:** Convert services (systemd → launchd equivalents)
- **Day 7:** Test on actual Mac hardware

### Week 3: Polish
- **Day 8-9:** Documentation, examples, templates
- **Day 10:** Final testing, regression tests
- **Days 11+:** Buffer for issues and refinement

## Example Configuration

### Inventory Entry
```nix
# inventory.nix
darwin-laptop = {
  type = "darwin-laptop";
  system = "aarch64-darwin";  # or x86_64-darwin
  devices = 3;
  overrides.extraUsers = [ "developer" ];
};
```

### Host Type
```nix
# hosts/types/darwin-laptop.nix
{ inputs, ... }:
{ config, lib, ... }:
{
  imports = [ (import ../darwin-common.nix { inherit inputs; }) ];
  
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";
  
  system.defaults = {
    dock.autohide = true;
    NSGlobalDomain.AppleKeyboardUIMode = 3;
  };
  
  ugaif.sw.enable = lib.mkDefault true;
  ugaif.sw.type = lib.mkDefault "desktop";
}
```

### Platform-Aware Service
```nix
# sw/desktop/services.nix
{
  config = lib.mkMerge [
    # Linux
    (lib.mkIf pkgs.stdenv.isLinux {
      services.displayManager.sddm.enable = true;
      systemd.services.updater = { ... };
    })
    
    # Darwin
    (lib.mkIf pkgs.stdenv.isDarwin {
      # No display manager needed (macOS native)
      launchd.agents.updater = { ... };
    })
  ];
}
```

## Testing Checklist

When implementing, verify:

- [ ] `nix flake check` passes with Darwin hosts
- [ ] Darwin laptop builds: `nix build .#darwinConfigurations.darwin-laptop1.system`
- [ ] All NixOS configs still build (no regression)
- [ ] User accounts work on Darwin
- [ ] Home Manager applies on Darwin
- [ ] External modules work on Darwin
- [ ] Services start correctly (launchd on Darwin, systemd on Linux)

## Common Pitfalls to Avoid

1. **Don't try to configure the display manager on Darwin** - macOS handles this
2. **Don't assume disk partitioning** - Darwin uses existing macOS partitions
3. **Remember: Different service managers** - systemd vs launchd have different APIs
4. **Watch out for Linux-specific packages** - Some packages don't work on Darwin
5. **Test on real hardware early** - Simulators don't catch everything

## Resources

- **nix-darwin repo**: https://github.com/LnL7/nix-darwin
- **nix-darwin manual**: https://daiderd.com/nix-darwin/manual/
- **Example configs**: Search GitHub for "darwinSystem" + "nix"
- **macOS defaults**: https://macos-defaults.com/

## When to Bail Out

Consider stopping if:
- No access to Mac hardware for testing
- Team has no macOS expertise
- Only need Home Manager (can do that without nix-darwin)
- Timeline is too aggressive (< 1 week)

## Decision Tree

```
Do you need to manage macOS systems?
├─ NO → Don't do this refactoring
└─ YES → Do you need system-level management?
    ├─ NO → Just use Home Manager (simpler)
    └─ YES → Do you have Mac hardware for testing?
        ├─ NO → Wait until you do
        └─ YES → ✅ Proceed with this refactoring
```

## Next Steps

If proceeding:
1. Read the full [DARWIN_SUPPORT_ASSESSMENT.md](../DARWIN_SUPPORT_ASSESSMENT.md)
2. Set up a test Mac (physical or VM)
3. Start with Phase 1 (Foundation)
4. Test early and often
5. Document as you go

## Questions?

See the full assessment document for:
- Detailed component breakdown
- Code examples for each change
- Risk analysis and mitigation strategies
- Alternative approaches
- Complete effort estimation

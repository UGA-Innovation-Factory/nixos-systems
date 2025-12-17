# Building Installation Media

This guide covers building installer ISOs, live images, and container artifacts from the nixos-systems flake.

## Table of Contents

- [Quick Start](#quick-start)
- [Available Artifacts](#available-artifacts)
- [Installer ISOs](#installer-isos)
- [Live ISOs](#live-isos)
- [Container Images](#container-images)
- [Remote Builders](#remote-builders)
- [Troubleshooting](#troubleshooting)

## Quick Start

```bash
# Build an installer ISO for a specific host
nix build github:UGA-Innovation-Factory/nixos-systems#installer-iso-nix-laptop1

# Result will be in result/iso/
ls -lh result/iso/
```

## Available Artifacts

List all available build outputs:

```bash
nix flake show github:UGA-Innovation-Factory/nixos-systems
```

Common artifact types:

| Artifact Type | Description | Example |
|--------------|-------------|---------|
| `installer-iso-*` | Auto-install ISO that installs configuration to disk | `installer-iso-nix-laptop1` |
| `iso-*` | Live ISO (bootable without installation) | `iso-nix-ephemeral1` |
| `ipxe-*` | iPXE netboot artifacts (kernel, initrd, script) | `ipxe-nix-ephemeral1` |
| `lxc-*` | LXC container tarball | `lxc-nix-builder` |
| `proxmox-*` | Proxmox VMA archive | `proxmox-nix-builder` |

## Installer ISOs

Installer ISOs automatically install the NixOS configuration to disk on first boot.

### Building Locally

```bash
# Build installer for a specific host
nix build .#installer-iso-nix-laptop1

# Result location
ls -lh result/iso/nixos-*.iso

# Copy to USB drive (replace /dev/sdX with your USB device)
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress
```

### Building from GitHub

```bash
nix build github:UGA-Innovation-Factory/nixos-systems#installer-iso-nix-laptop1
```

### Using the Installer

1. Boot from the ISO
2. The system will automatically partition the disk and install NixOS
3. After installation completes, remove the USB drive and reboot
4. Log in with the configured user credentials

**Note:** The installer will **erase all data** on the target disk specified in `ugaif.host.filesystem.device`.

## Live ISOs

Live ISOs boot into a temporary system without installing to disk. Useful for:
- Testing configurations
- Recovery operations
- Ephemeral/stateless systems

### Building Live ISOs

```bash
# Build live ISO
nix build .#iso-nix-ephemeral1

# Result location
ls -lh result/iso/nixos-*.iso
```

### Stateless Kiosk Systems

For PXE netboot kiosks, use the `ipxe-*` artifacts:

```bash
# Build iPXE artifacts
nix build .#ipxe-nix-ephemeral1

# Result contains:
# - bzImage (kernel)
# - initrd (initial ramdisk)
# - netboot.ipxe (iPXE script)
ls -lh result/
```

## Container Images

### LXC Containers

Build LXC container tarballs for Proxmox or other LXC hosts:

```bash
# Build LXC tarball
nix build .#lxc-nix-builder

# Result location
ls -lh result/tarball/nixos-*.tar.xz
```

**Importing to Proxmox:**

```bash
# Copy tarball to Proxmox host
scp result/tarball/nixos-*.tar.xz root@proxmox:/var/lib/vz/template/cache/

# Create container from Proxmox CLI
pct create 100 local:vztmpl/nixos-*.tar.xz \
  --hostname nix-builder \
  --memory 4096 \
  --cores 4 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp
```

See [installer/PROXMOX_LXC.md](../installer/PROXMOX_LXC.md) for detailed Proxmox deployment instructions.

### Proxmox VMA

Build Proxmox-specific VMA archives:

```bash
# Build Proxmox VMA
nix build .#proxmox-nix-builder

# Result location
ls -lh result/
```

## Remote Builders

Speed up builds by offloading to build servers.

### One-Time Remote Build

```bash
nix build .#installer-iso-nix-laptop1 \
  --builders "ssh://engr-ugaif@nix-builder x86_64-linux"
```

### Persistent Configuration

Add to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:

```conf
builders = ssh://engr-ugaif@nix-builder x86_64-linux
```

Then build normally:

```bash
nix build .#installer-iso-nix-laptop1
```

### SSH Key Setup

For remote builders, ensure SSH keys are configured:

```bash
# Generate SSH key if needed
ssh-keygen -t ed25519

# Copy to builder
ssh-copy-id engr-ugaif@nix-builder

# Test connection
ssh engr-ugaif@nix-builder
```

### Multiple Builders

Configure multiple build servers:

```conf
builders = ssh://engr-ugaif@nix-builder x86_64-linux ; ssh://engr-ugaif@nix-builder2 x86_64-linux
```

## Troubleshooting

### Build Errors

**Check configuration validity:**
```bash
nix flake check --show-trace
```

**Test specific host build:**
```bash
nix build .#nixosConfigurations.nix-laptop1.config.system.build.toplevel
```

### Remote Builder Issues

**Test SSH access:**
```bash
ssh engr-ugaif@nix-builder
```

**Check builder disk space:**
```bash
ssh engr-ugaif@nix-builder df -h
```

**Temporarily disable remote builds:**

In `inventory.nix`:
```nix
ugaif.sw.remoteBuild.enable = false;
```

### Out of Disk Space

**Clean up Nix store:**
```bash
nix-collect-garbage -d
nix store optimise
```

**Check space:**
```bash
df -h /nix
```

### ISO Won't Boot

**Verify ISO integrity:**
```bash
sha256sum result/iso/nixos-*.iso
```

**Check USB write:**
```bash
# Use correct block size and sync
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress && sync
```

**Try alternative boot mode:**
- UEFI systems: Try legacy BIOS mode
- Legacy BIOS: Try UEFI mode

## See Also

- [README.md](../README.md) - Main documentation
- [INVENTORY.md](INVENTORY.md) - Host configuration guide
- [installer/PROXMOX_LXC.md](../installer/PROXMOX_LXC.md) - Proxmox deployment guide

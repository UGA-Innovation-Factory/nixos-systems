# Proxmox LXC Deployment

This directory contains tools for building and deploying NixOS LXC containers to Proxmox Virtual Environment.

## Quick Start

### Prerequisites

1. **Nix with flakes enabled** on your build machine
2. **SSH access** to your Proxmox host
3. **A NixOS configuration** with `boot.isContainer = true` and `"lxc"` in `buildMethods`

### Basic Deployment

```bash
# Build and deploy in one command
./installer/deploy-proxmox-lxc.sh nix-builder pve1.example.com --vmid 200 --start

# Or with more options
./installer/deploy-proxmox-lxc.sh usda-dash root@192.168.1.10 \
  --vmid 300 \
  --memory 2048 \
  --cores 2 \
  --rootfs 16 \
  --net "name=eth0,bridge=vmbr0,ip=192.168.1.100/24,gw=192.168.1.1" \
  --start
```

## Configuration

### Making a Host LXC-Compatible

Add the host to `inventory.nix` with the `nix-lxc` type or ensure it has the appropriate configuration:

```nix
{
  nix-lxc = {
    devices = {
      "my-container" = { };
    };
    overrides = {
      ugaif.host.useHostPrefix = false;
      ugaif.host.buildMethods = [ "lxc" ];
    };
  };
}
```

Your host type configuration (`hosts/types/nix-lxc.nix`) should include:

```nix
{
  boot.isContainer = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  disko.enableConfig = lib.mkForce false;
  
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];
}
```

### Building the Tarball

```bash
# Build LXC tarball for a specific host
nix build .#lxc-nix-builder

# The tarball will be in ./result/
ls -lh result/
```

## Script Usage

### Command Syntax

```bash
./installer/deploy-proxmox-lxc.sh <hostname> <proxmox-host> [options]
```

### Arguments

- `hostname`: NixOS hostname to build (must exist in your flake)
- `proxmox-host`: Proxmox server address (e.g., `pve1.example.com` or `root@192.168.1.10`)

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--vmid ID` | Container ID | Auto-assigned |
| `--storage NAME` | Storage for container filesystem | `local-lvm` |
| `--storage-upload NAME` | Storage for tarball upload | `local` |
| `--memory MB` | Memory in MB | `512` |
| `--cores NUM` | CPU cores | `1` |
| `--rootfs SIZE` | Root filesystem size (e.g., `8`, `16G`) | `8` |
| `--net NETCONFIG` | Network configuration | `name=eth0,bridge=vmbr0,ip=dhcp` |
| `--hostname NAME` | Override container hostname | Same as NixOS hostname |
| `--description TEXT` | Container description | `NixOS LXC - <hostname>` |
| `--unprivileged` | Create unprivileged container | Privileged |
| `--start` | Start container after creation | Don't start |
| `--template` | Convert to template after creation | Regular container |
| `--skip-build` | Skip building tarball | Build |
| `--skip-upload` | Skip uploading tarball | Upload |
| `--ssh-user USER` | SSH user for Proxmox | `root` |
| `--ssh-port PORT` | SSH port for Proxmox | `22` |

## Examples

### Example 1: Basic Container

Deploy a simple container with DHCP networking:

```bash
./installer/deploy-proxmox-lxc.sh nix-builder pve1.example.com \
  --vmid 200 \
  --start
```

### Example 2: Production Container with Static IP

Deploy with specific resources and static networking:

```bash
./installer/deploy-proxmox-lxc.sh usda-dash pve1.example.com \
  --vmid 300 \
  --memory 4096 \
  --cores 4 \
  --rootfs 32 \
  --net "name=eth0,bridge=vmbr0,ip=192.168.1.100/24,gw=192.168.1.1" \
  --description "USDA Dashboard Production" \
  --start
```

### Example 3: Create a Template

Build a template for cloning:

```bash
./installer/deploy-proxmox-lxc.sh nix-builder pve1.example.com \
  --vmid 999 \
  --description "NixOS LXC Template" \
  --template
```

Then clone it:

```bash
# On the Proxmox host
pct clone 999 201 --hostname nix-builder-01
pct start 201
```

### Example 4: Reuse Existing Tarball

If you've already built and uploaded a tarball:

```bash
./installer/deploy-proxmox-lxc.sh nix-builder pve1.example.com \
  --vmid 202 \
  --skip-build \
  --skip-upload \
  --start
```

### Example 5: Using SSH Key Authentication

```bash
./installer/deploy-proxmox-lxc.sh nix-builder pve1.example.com \
  --vmid 200 \
  --ssh-user admin \
  --ssh-port 2222 \
  --start
```

## Container Management

### Entering the Container

After deployment, access the container from the Proxmox host:

```bash
# SSH to Proxmox
ssh root@pve1.example.com

# Enter the container
pct enter 200

# Set up the environment (important!)
source /etc/set-environment
# or
. /etc/profile
```

### First Boot Setup

Inside the container:

```bash
# Verify NixOS is running
nixos-version

# Check system status
systemctl status

# Apply configuration changes
nixos-rebuild switch
```

### Common Management Commands

On the Proxmox host:

```bash
# Container status
pct status 200

# Start/stop/restart
pct start 200
pct stop 200
pct restart 200

# View console
pct console 200

# Container configuration
pct config 200

# Resize disk
pct resize 200 rootfs +8G

# Update memory
pct set 200 --memory 2048

# Update cores
pct set 200 --cores 4

# Backup container
vzdump 200 --compress zstd --mode snapshot

# Delete container
pct stop 200
pct destroy 200
```

## Troubleshooting

### Black Console Issue

If the Proxmox console appears black:

1. Just type `root` and press Enter - new text will render
2. Or modify the container to use `/dev/console`:
   ```bash
   # In /etc/pve/lxc/200.conf
   lxc.console = /dev/console
   ```

### Mount Errors During nixos-rebuild

These warnings are normal and don't affect functionality:

```
mount: /dev: cannot remount devtmpfs read-write, is write-protected.
mount: /proc: cannot remount proc read-write, is write-protected.
```

These occur because special filesystems are managed by Proxmox, not the container.

### Commands Not Found After pct enter

Set up the environment:

```bash
source /etc/set-environment
# or
. /etc/profile
# or if that fails
/run/current-system/activate
```

### Build Failures

Check available LXC targets:

```bash
# List all available packages
nix flake show

# Check specific host configuration
nix eval .#nixosConfigurations.nix-builder.config.boot.isContainer
# Should output: true

# Check build methods
nix eval .#nixosConfigurations.nix-builder.config.ugaif.host.buildMethods
# Should include: "lxc"
```

### Upload Failures

Ensure SSH key authentication is set up:

```bash
# Copy your SSH key to Proxmox
ssh-copy-id root@pve1.example.com

# Test connection
ssh root@pve1.example.com "pvesh get /cluster/resources"
```

Check Proxmox storage paths:

```bash
# On Proxmox host, verify paths exist
ls -la /var/lib/vz/template/cache/
pvesm status
```

### Network Issues

If the container can't reach the network:

1. Check bridge configuration in Proxmox
2. Verify VLAN settings if applicable
3. Try DHCP first before static IP
4. Check firewall rules

```bash
# Inside container
ip addr show
ip route show
ping -c 3 8.8.8.8
```

## Advanced Configuration

### Custom LXC Configuration

After creation, you can edit `/etc/pve/lxc/<VMID>.conf` on the Proxmox host:

```bash
# Add additional features
lxc.cap.drop:
lxc.mount.auto: cgroup:mixed proc:mixed sys:mixed
lxc.cgroup2.devices.allow: c 10:200 rwm

# Mount host directory
mp0: /mnt/data,mp=/data

# Additional network interface
net1: name=eth1,bridge=vmbr1,ip=192.168.2.100/24
```

### Unprivileged Containers

For better security, use unprivileged containers:

```bash
./installer/deploy-proxmox-lxc.sh nix-builder pve1.example.com \
  --vmid 200 \
  --unprivileged \
  --start
```

Note: Some NixOS features may require privileged containers.

### Nesting Docker or Other Containers

Enable nesting (already done by the script):

```bash
# In /etc/pve/lxc/200.conf
features: nesting=1
```

Inside the container:

```nix
# In your NixOS configuration
{
  virtualisation.docker.enable = true;
}
```

## Integration with Your Flake

The script works with any host in your `nixosConfigurations` that:

1. Has `boot.isContainer = true`
2. Has `"lxc"` in `ugaif.host.buildMethods`
3. Imports the Proxmox LXC module

Your `artifacts.nix` automatically exposes these as `lxc-<hostname>` packages.

## Automation

### CI/CD Integration

```bash
#!/bin/bash
# deploy-to-staging.sh

set -e

HOSTNAME="$1"
PROXMOX_HOST="pve-staging.example.com"
VMID_BASE=200

# Build
nix build ".#lxc-${HOSTNAME}"

# Deploy
./installer/deploy-proxmox-lxc.sh "$HOSTNAME" "$PROXMOX_HOST" \
  --vmid $((VMID_BASE + $(hostname | md5sum | cut -d' ' -f1 | head -c 3))) \
  --memory 2048 \
  --start
```

### Batch Deployment

```bash
#!/bin/bash
# deploy-multiple.sh

PROXMOX_HOST="pve1.example.com"
VMID=200

for HOST in nix-builder usda-dash; do
  ./installer/deploy-proxmox-lxc.sh "$HOST" "$PROXMOX_HOST" \
    --vmid $VMID \
    --start
  VMID=$((VMID + 1))
done
```

## See Also

- [Proxmox LXC Documentation](https://pve.proxmox.com/wiki/Linux_Container)
- [NixOS Containers](https://nixos.wiki/wiki/NixOS_Containers)
- [NixOS Manual: Container Management](https://nixos.org/manual/nixos/stable/#ch-containers)

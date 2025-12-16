#!/usr/bin/env bash
# ============================================================================
# Proxmox LXC Deployment Script
# ============================================================================
# This script builds NixOS LXC container tarballs and deploys them to Proxmox.
# It handles the complete workflow: build, upload, create, and configure.
#
# Usage:
#   ./deploy-proxmox-lxc.sh <hostname> <proxmox-host> [options]
#
# Example:
#   ./deploy-proxmox-lxc.sh nix-builder pve1.example.com --vmid 200 --storage local-lvm
#
# See README in installer/ directory for detailed usage instructions.

set -euo pipefail

# ========== Configuration ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARBALL_DIR="$PROJECT_ROOT/result"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ========== Helper Functions ==========

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

usage() {
    cat <<EOF
Usage: $0 <hostname> <proxmox-host> [options]

Arguments:
  hostname          NixOS hostname to build (e.g., nix-builder, usda-dash)
  proxmox-host      Proxmox host address (e.g., pve1.example.com or root@192.168.1.10)

Options:
  --vmid ID         Container ID (default: auto-assigned by Proxmox)
  --storage NAME    Storage for container (default: local-lvm)
  --storage-upload NAME  Storage for tarball upload (default: local)
  --memory MB       Memory in MB (default: 512)
  --cores NUM       CPU cores (default: 1)
  --rootfs SIZE     Root filesystem size (default: 8G)
  --net NETCONFIG   Network config (default: name=eth0,bridge=vmbr0,ip=dhcp)
  --hostname NAME   Override container hostname (default: same as NixOS hostname)
  --description TEXT Container description (default: "NixOS LXC - <hostname>")
  --unprivileged    Create unprivileged container (default: privileged)
  --start           Start container after creation
  --template        Convert to template after creation
  --skip-build      Skip building the tarball (use existing result)
  --skip-upload     Skip uploading tarball (assume already uploaded)
  --ssh-user USER   SSH user for Proxmox host (default: root)
  --ssh-port PORT   SSH port for Proxmox host (default: 22)
  --help, -h        Show this help message

Examples:
  # Basic deployment with auto-assigned ID
  $0 nix-builder pve1.example.com

  # Deploy with specific ID and resources
  $0 nix-builder pve1.example.com --vmid 200 --memory 2048 --cores 2

  # Create a template
  $0 nix-builder pve1.example.com --vmid 999 --template

  # Deploy with static IP
  $0 usda-dash pve1.example.com --vmid 300 --net "name=eth0,bridge=vmbr0,ip=192.168.1.100/24,gw=192.168.1.1"

  # Use existing tarball (skip build)
  $0 nix-builder pve1.example.com --skip-build --vmid 201

EOF
    exit 1
}

# ========== Parse Arguments ==========

if [[ $# -lt 2 ]]; then
    usage
fi

HOSTNAME="$1"
PROXMOX_HOST="$2"
shift 2

# Default values
VMID=""
STORAGE="local-lvm"
STORAGE_UPLOAD="local"
MEMORY="512"
CORES="1"
ROOTFS_SIZE="8"
NETWORK="name=eth0,bridge=vmbr0,ip=dhcp,firewall=1"
CONTAINER_HOSTNAME=""
DESCRIPTION=""
UNPRIVILEGED=false
START_CONTAINER=false
CREATE_TEMPLATE=false
SKIP_BUILD=false
SKIP_UPLOAD=false
SSH_USER="root"
SSH_PORT="22"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --vmid)
            VMID="$2"
            shift 2
            ;;
        --storage)
            STORAGE="$2"
            shift 2
            ;;
        --storage-upload)
            STORAGE_UPLOAD="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --cores)
            CORES="$2"
            shift 2
            ;;
        --rootfs)
            ROOTFS_SIZE="$2"
            shift 2
            ;;
        --net)
            NETWORK="$2"
            shift 2
            ;;
        --hostname)
            CONTAINER_HOSTNAME="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --unprivileged)
            UNPRIVILEGED=true
            shift
            ;;
        --start)
            START_CONTAINER=true
            shift
            ;;
        --template)
            CREATE_TEMPLATE=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        --ssh-user)
            SSH_USER="$2"
            shift 2
            ;;
        --ssh-port)
            SSH_PORT="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Set defaults if not provided
if [[ -z "$CONTAINER_HOSTNAME" ]]; then
    CONTAINER_HOSTNAME="$HOSTNAME"
fi

if [[ -z "$DESCRIPTION" ]]; then
    DESCRIPTION="NixOS LXC - $HOSTNAME"
fi

# Construct SSH connection string
if [[ "$PROXMOX_HOST" == *"@"* ]]; then
    SSH_TARGET="$PROXMOX_HOST"
else
    SSH_TARGET="${SSH_USER}@${PROXMOX_HOST}"
fi

SSH_OPTS="-P $SSH_PORT"
SSH_CMD_OPTS="-p $SSH_PORT"

# ========== Main Script ==========

log_info "Proxmox LXC Deployment for: $HOSTNAME"
log_info "Target Proxmox Host: $PROXMOX_HOST"
log_info "Container Hostname: $CONTAINER_HOSTNAME"

# Step 1: Build the tarball
if [[ "$SKIP_BUILD" == true ]]; then
    log_warning "Skipping build step"
else
    log_info "Building LXC tarball for $HOSTNAME..."
    cd "$PROJECT_ROOT"
    
    if ! nix build ".#lxc-${HOSTNAME}" --show-trace; then
        log_error "Failed to build LXC tarball for $HOSTNAME"
        log_info "Available LXC targets:"
        nix flake show 2>/dev/null | grep "lxc-" || log_warning "Could not list available targets"
        exit 1
    fi
    
    log_success "Build completed"
fi

# Find the tarball (check both root and tarball subdirectory)
TARBALL_PATH=$(find -L "$TARBALL_DIR" -type f \( -name "nixos-system-*.tar.xz" -o -name "nixos-image-*.tar.xz" -o -name "tarball.tar.xz" \) 2>/dev/null | head -n1)

if [[ ! -f "$TARBALL_PATH" ]]; then
    log_error "Could not find tarball in $TARBALL_DIR"
    log_info "Contents of result directory:"
    ls -la "$TARBALL_DIR" || log_warning "Result directory not found"
    log_info "Checking tarball subdirectory:"
    ls -la "$TARBALL_DIR/tarball/" 2>/dev/null || true
    exit 1
fi

log_info "Found tarball: $TARBALL_PATH"

# Get tarball filename for Proxmox naming convention
TARBALL_BASENAME=$(basename "$TARBALL_PATH")
NIXOS_VERSION=$(nix eval --raw ".#nixosConfigurations.${HOSTNAME}.config.system.nixos.release" 2>/dev/null || echo "unknown")
BUILD_DATE=$(date +%Y%m%d)
PROXMOX_TARBALL_NAME="nixos-${NIXOS_VERSION}-${HOSTNAME}_${BUILD_DATE}_amd64.tar.xz"

log_info "Proxmox tarball name: $PROXMOX_TARBALL_NAME"

# Step 2: Upload tarball to Proxmox
if [[ "$SKIP_UPLOAD" == true ]]; then
    log_warning "Skipping upload step"
else
    log_info "Uploading tarball to Proxmox host..."
    
    # First, copy to a temporary location on Proxmox host
    if ! scp $SSH_OPTS "$TARBALL_PATH" "${SSH_TARGET}:/tmp/${PROXMOX_TARBALL_NAME}"; then
        log_error "Failed to upload tarball to Proxmox host"
        exit 1
    fi
    
    # Move to Proxmox storage
    log_info "Moving tarball to Proxmox storage: ${STORAGE_UPLOAD}:vztmpl/"
    if ! ssh $SSH_CMD_OPTS "$SSH_TARGET" "mv /tmp/${PROXMOX_TARBALL_NAME} /var/lib/vz/template/cache/${PROXMOX_TARBALL_NAME}"; then
        log_error "Failed to move tarball to Proxmox storage"
        log_info "Attempting to create vztmpl directory if it doesn't exist..."
        ssh $SSH_CMD_OPTS "$SSH_TARGET" "mkdir -p /var/lib/vz/template/cache && mv /tmp/${PROXMOX_TARBALL_NAME} /var/lib/vz/template/cache/${PROXMOX_TARBALL_NAME}" || {
            log_error "Failed to move tarball even after creating directory"
            exit 1
        }
    fi
    
    log_success "Tarball uploaded successfully"
fi

# Step 3: Get next available VMID if not specified
if [[ -z "$VMID" ]]; then
    log_info "Auto-assigning VMID..."
    VMID=$(ssh $SSH_CMD_OPTS "$SSH_TARGET" "pvesh get /cluster/nextid")
    log_info "Assigned VMID: $VMID"
fi

# Step 4: Check if VMID already exists
if ssh $SSH_CMD_OPTS "$SSH_TARGET" "pct status $VMID" &>/dev/null; then
    log_error "Container with VMID $VMID already exists!"
    log_info "Please choose a different VMID or remove the existing container:"
    log_info "  pct stop $VMID && pct destroy $VMID"
    exit 1
fi

# Step 5: Create the container
log_info "Creating LXC container with VMID: $VMID"

CREATE_CMD="pct create $VMID ${STORAGE_UPLOAD}:vztmpl/${PROXMOX_TARBALL_NAME}"
CREATE_CMD="$CREATE_CMD --description '${DESCRIPTION}'"
CREATE_CMD="$CREATE_CMD --hostname '${CONTAINER_HOSTNAME}'"
CREATE_CMD="$CREATE_CMD --memory $MEMORY"
CREATE_CMD="$CREATE_CMD --cores $CORES"
CREATE_CMD="$CREATE_CMD --rootfs ${STORAGE}:${ROOTFS_SIZE}"
CREATE_CMD="$CREATE_CMD --net0 $NETWORK"
CREATE_CMD="$CREATE_CMD --ostype unmanaged"
CREATE_CMD="$CREATE_CMD --features nesting=1"

if [[ "$UNPRIVILEGED" == true ]]; then
    CREATE_CMD="$CREATE_CMD --unprivileged 1"
fi

log_info "Executing: $CREATE_CMD"

if ! ssh $SSH_CMD_OPTS "$SSH_TARGET" "$CREATE_CMD"; then
    log_error "Failed to create container"
    exit 1
fi

log_success "Container created successfully"

# Step 6: Configure container for NixOS
log_info "Configuring container for NixOS..."

# Set init command
CONFIG_FILE="/etc/pve/lxc/${VMID}.conf"
ssh $SSH_CMD_OPTS "$SSH_TARGET" "echo 'lxc.init.cmd: /sbin/init' >> $CONFIG_FILE"

# Optional: Add additional LXC configuration for better NixOS compatibility
ssh $SSH_CMD_OPTS "$SSH_TARGET" "cat >> $CONFIG_FILE <<'EOFCONF'

# NixOS compatibility settings
lxc.autodev: 1
lxc.pty.max: 1024
lxc.cap.drop:
EOFCONF
"

log_success "Container configured for NixOS"

# Step 7: Convert to template if requested
if [[ "$CREATE_TEMPLATE" == true ]]; then
    log_info "Converting container to template..."
    ssh $SSH_CMD_OPTS "$SSH_TARGET" "pct template $VMID"
    log_success "Container converted to template"
fi

# Step 8: Start container if requested
if [[ "$START_CONTAINER" == true ]] && [[ "$CREATE_TEMPLATE" == false ]]; then
    log_info "Starting container..."
    if ssh $SSH_CMD_OPTS "$SSH_TARGET" "pct start $VMID"; then
        log_success "Container started successfully"
        
        # Wait a bit for container to boot
        log_info "Waiting for container to boot..."
        sleep 5
        
        log_info "Container status:"
        ssh $SSH_CMD_OPTS "$SSH_TARGET" "pct status $VMID"
        
        log_info ""
        log_info "To enter the container, run on Proxmox host:"
        log_info "  pct enter $VMID"
        log_info ""
        log_info "Once inside, initialize the environment with:"
        log_info "  source /etc/set-environment"
        log_info "  or"
        log_info "  . /etc/profile"
    else
        log_warning "Failed to start container, but container was created successfully"
    fi
fi

# Step 9: Display summary
log_success "========================================="
log_success "Deployment Complete!"
log_success "========================================="
log_info "VMID: $VMID"
log_info "Hostname: $CONTAINER_HOSTNAME"
log_info "Storage: $STORAGE"
log_info "Memory: ${MEMORY}MB"
log_info "Cores: $CORES"
log_info ""
log_info "Next steps:"
log_info "1. Access Proxmox web UI: https://${PROXMOX_HOST}:8006"
log_info "2. Or SSH to Proxmox and enter container:"
log_info "     ssh ${SSH_TARGET}"
log_info "     pct enter $VMID"
log_info ""
log_info "Inside the container:"
log_info "  # Set up environment"
log_info "  source /etc/set-environment"
log_info "  # or"
log_info "  . /etc/profile"
log_info ""
log_info "  # Verify NixOS installation"
log_info "  nixos-version"
log_info ""
log_info "  # Make configuration changes"
log_info "  nixos-rebuild switch"
log_info ""

if [[ "$CREATE_TEMPLATE" == true ]]; then
    log_info "Template created! Clone it with:"
    log_info "  pct clone $VMID <new-vmid> --hostname <new-hostname>"
fi

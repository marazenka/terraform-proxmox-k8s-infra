#!/bin/bash
set -e

# --- Configuration ---
TEMPLATE_ID=9000
NEW_VM_ID=666
NEW_VM_NAME="devops-heorhi"
STORAGE="local-lvm"
BRIDGE="vmbr0"

# SSH
SSH_KEY="ssh-ed25519 AAAA.. user@host"
VM_USER="ubuntu"

# Resources
CPU_CORES=2
MEMORY=8192
DISK_SIZE="50G"

# --- 1. Check if Template exists ---
if ! qm status $TEMPLATE_ID >/dev/null 2>&1; then
    echo "Error: Template $TEMPLATE_ID not found!"
    exit 1
fi

# --- 2. Check if New VM ID is already taken ---
if qm status $NEW_VM_ID >/dev/null 2>&1; then
    echo "Error: VM $NEW_VM_ID already exists. Choose another ID."
    exit 1
fi

echo "Creating VM '$NEW_VM_NAME' (ID: $NEW_VM_ID) from template $TEMPLATE_ID..."

# --- 3. Clone the Template ---
# --full 1 - Full Clone
qm clone $TEMPLATE_ID $NEW_VM_ID --name "$NEW_VM_NAME" --full 1

# --- 4. Configure Resources ---
echo "Configuring CPU, RAM and Disk..."
qm set $NEW_VM_ID \
    --cores $CPU_CORES \
    --memory $MEMORY \
    --onboot 1 \
    --agent enabled=1
qm resize $NEW_VM_ID scsi0 $DISK_SIZE

# --- 5. Optional: Cloud-Init Network ---
# qm set $NEW_VM_ID --ipconfig0 ip=dhcp
# or
qm set $NEW_VM_ID --ipconfig0 ip=192.168.50.66/24,gw=192.168.50.1

echo "Configuring Cloud-Init with SSH key..."
qm set $NEW_VM_ID --ciuser $VM_USER
qm set $NEW_VM_ID --sshkeys <(echo "$SSH_KEY")


echo "---"
echo "VM $NEW_VM_NAME has been created!"
echo "You can now start it with: qm start $NEW_VM_ID"

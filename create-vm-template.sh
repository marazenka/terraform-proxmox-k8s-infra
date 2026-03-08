#!/bin/bash
set -e

# --- Configuration ---
VM_ID=9000
VM_NAME="ubuntu-2404-template"
STORAGE="local-lvm"
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_NAME="ubuntu-24.04.qcow2"

# --- 1. Check if the template already exists ---
if qm status $VM_ID >/dev/null 2>&1; then
    echo "Template $VM_ID already exists. Skipping..."
    exit 0
fi

echo "Starting creation of $VM_NAME..."

# --- 2. Download the image if it doesn't exist ---
if [ ! -f /root/$IMAGE_NAME ]; then
    wget -O /root/$IMAGE_NAME $IMAGE_URL
fi

# --- 3. Create the VM and import the disk ---
# Create the VM shell
qm create $VM_ID --name "$VM_NAME" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the qcow2 file into Proxmox storage
qm importdisk $VM_ID /root/$IMAGE_NAME $STORAGE

# Attach the disk to the VM and set up Cloud-Init
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0
qm set $VM_ID --ide2 $STORAGE:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0

# Configure video output to Serial for Cloud-Init visibility
qm set $VM_ID --serial0 socket --vga serial0

# Enable QEMU Guest Agent for IP reporting
qm set $VM_ID --agent enabled=1

# --- 4. Convert the VM into a Proxmox Template ---
qm template $VM_ID

echo "Done! Template $VM_ID has been created successfully."
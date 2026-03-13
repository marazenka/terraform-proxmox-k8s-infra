locals {
  # Build the CIDR prefix (e.g. "24") to append to computed host IPs.
  cidr_prefix = "/${split("/", var.network_cidr)[1]}"
}

# ---------------------------------------------------------------------------
# Load Balancer (HAProxy)
# Set haproxy_count = 1 to provision; 0 disables the resource entirely.
# ---------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "haproxy" {
  count     = var.haproxy_count
  name      = "k8s-haproxy-${count.index + 1}"
  node_name = var.node_name
  vm_id     = var.haproxy_vm_id_base + count.index

  clone { vm_id = var.template_vm_id }
  agent { enabled = false }

  cpu {
    cores = var.haproxy_cpu_cores
    type  = "host"
  }

  memory { dedicated = var.haproxy_memory }

  disk {
    datastore_id = var.disk_datastore
    interface    = "scsi0"
    size         = var.haproxy_disk_size
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, var.haproxy_ip_offset + count.index)}${local.cidr_prefix}"
        gateway = var.network_gateway
      }
    }
    user_account {
      username = var.vm_user
      keys     = [var.ssh_public_key]
    }
  }

  network_device { bridge = var.network_bridge }

  on_boot = true

  startup {
    order      = 1
    up_delay   = 30
    down_delay = 30
  }
}

# ---------------------------------------------------------------------------
# Kubernetes Masters
# ---------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "masters" {
  count     = var.master_count
  name      = "k8s-master-${count.index + 1}"
  node_name = var.node_name
  vm_id     = var.master_vm_id_base + count.index

  clone { vm_id = var.template_vm_id }
  agent { enabled = false }

  cpu {
    cores = var.master_cpu_cores
    type  = "host"
  }

  memory { dedicated = var.master_memory }

  disk {
    datastore_id = var.disk_datastore
    interface    = "scsi0"
    size         = var.master_disk_size
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, var.master_ip_start_offset + count.index)}${local.cidr_prefix}"
        gateway = var.network_gateway
      }
    }
    user_account {
      username = var.vm_user
      keys     = [var.ssh_public_key]
    }
  }

  network_device { bridge = var.network_bridge }

  on_boot = true

  startup {
    order    = 2
    up_delay = 60
  }
}

# ---------------------------------------------------------------------------
# Kubernetes Workers
# ---------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "workers" {
  count     = var.worker_count
  name      = "k8s-worker-${count.index + 1}"
  node_name = var.node_name
  vm_id     = var.worker_vm_id_base + count.index

  clone { vm_id = var.template_vm_id }
  agent { enabled = false }

  cpu {
    cores = var.worker_cpu_cores
    type  = "host"
  }

  memory { dedicated = var.worker_memory }

  disk {
    datastore_id = var.disk_datastore
    interface    = "scsi0"
    size         = var.worker_disk_size
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, var.worker_ip_start_offset + count.index)}${local.cidr_prefix}"
        gateway = var.network_gateway
      }
    }
    user_account {
      username = var.vm_user
      keys     = [var.ssh_public_key]
    }
  }

  network_device { bridge = var.network_bridge }

  on_boot = true

  startup {
    order = 3
  }
}

# ---------------------------------------------------------------------------
# GPU Nodes (PCIe passthrough)
#
# Prerequisites on the Proxmox host:
#   - IOMMU enabled in BIOS/UEFI (VT-d for Intel / AMD-Vi for AMD)
#   - Kernel boot args: intel_iommu=on iommu=pt  (or amd_iommu=on)
#   - GPU bound to vfio-pci driver, not nvidia/nouveau
#   - GPU and its audio function in the same IOMMU group
#
# Set gpu_node_count = 1 to provision.
# ---------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "gpu_nodes" {
  count     = var.gpu_node_count
  name      = "k8s-gpu-${count.index + 1}"
  node_name = var.node_name
  vm_id     = var.gpu_node_vm_id_base + count.index

  # q35 chipset + UEFI are required for PCIe passthrough
  machine = "q35"
  bios    = "ovmf"

  clone { vm_id = var.template_vm_id }
  agent { enabled = false }

  cpu {
    cores = var.gpu_node_cpu_cores
    type  = "host"
  }

  memory { dedicated = var.gpu_node_memory }

  disk {
    datastore_id = var.disk_datastore
    interface    = "scsi0"
    size         = var.gpu_node_disk_size
  }

  # Reference a Proxmox Resource Mapping instead of a raw PCI address.
  # Create the mapping first: Datacenter → Resource Mappings → PCI Devices → Add
  hostpci {
    device  = "hostpci0"
    mapping = var.gpu_mapping_name
    pcie    = true
    rombar  = true
    xvga    = false
  }

  # Disable virtual VGA — GPU is the sole display adapter
  vga { type = "none" }

  initialization {
    ip_config {
      ipv4 {
        address = "${cidrhost(var.network_cidr, var.gpu_node_ip_offset + count.index)}${local.cidr_prefix}"
        gateway = var.network_gateway
      }
    }
    user_account {
      username = var.vm_user
      keys     = [var.ssh_public_key]
    }
  }

  network_device { bridge = var.network_bridge }

  on_boot = true

  startup {
    order = 4
  }
}
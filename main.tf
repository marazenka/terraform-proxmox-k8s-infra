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
# ==============================================================================
# Proxmox Connection
# ==============================================================================

variable "proxmox_endpoint" {
  description = "URL of the Proxmox API endpoint (e.g. https://192.168.50.50:8006/)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the format '<user>@<realm>!<token-id>=<uuid>'"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS certificate verification for the Proxmox endpoint"
  type        = bool
  default     = true
}

# ==============================================================================
# Proxmox Infrastructure
# ==============================================================================

variable "node_name" {
  description = "Proxmox node name where VMs will be created"
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "VM ID of the Ubuntu cloud-init template to clone from"
  type        = number
  default     = 9000
}

# ==============================================================================
# Network
# ==============================================================================

variable "network_cidr" {
  description = "Network CIDR shared by all VMs (e.g. 192.168.50.0/24). Used to compute per-VM IPs via cidrhost()."
  type        = string
  default     = "192.168.50.0/24"
}

variable "network_gateway" {
  description = "Default gateway IP for all VMs"
  type        = string
  default     = "192.168.50.1"
}

variable "network_bridge" {
  description = "Proxmox Linux bridge to attach VM NICs to"
  type        = string
  default     = "vmbr0"
}

# ==============================================================================
# Storage
# ==============================================================================

variable "disk_datastore" {
  description = "Proxmox storage ID for VM root disks"
  type        = string
  default     = "local-lvm"
}

variable "haproxy_disk_size" {
  description = "Root disk size in GiB for HAProxy nodes"
  type        = number
  default     = 20
}

variable "master_disk_size" {
  description = "Root disk size in GiB for Kubernetes master nodes"
  type        = number
  default     = 25
}

variable "worker_disk_size" {
  description = "Root disk size in GiB for Kubernetes worker nodes"
  type        = number
  default     = 50
}

# ==============================================================================
# VM Access
# ==============================================================================

variable "vm_user" {
  description = "OS username created via cloud-init on every VM"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key injected into every VM via cloud-init"
  type        = string
  sensitive   = true
}

# ==============================================================================
# HAProxy (Load Balancer)
# ==============================================================================

variable "haproxy_count" {
  description = "Number of HAProxy VMs to create. Set to 0 to skip."
  type        = number
  default     = 0
}

variable "haproxy_vm_id_base" {
  description = "Base VM ID for HAProxy nodes. Each subsequent node gets base + index."
  type        = number
  default     = 100
}

variable "haproxy_ip_offset" {
  description = "Host offset within network_cidr for the first HAProxy node (e.g. 100 → .100, 101 → .101, …)"
  type        = number
  default     = 100
}

variable "haproxy_cpu_cores" {
  description = "Number of vCPUs allocated to each HAProxy VM"
  type        = number
  default     = 2
}

variable "haproxy_memory" {
  description = "RAM in MiB allocated to each HAProxy VM"
  type        = number
  default     = 2048
}

# ==============================================================================
# Kubernetes Masters
# ==============================================================================

variable "master_count" {
  description = "Number of Kubernetes master nodes to create"
  type        = number
  default     = 1
}

variable "master_vm_id_base" {
  description = "Base VM ID for master nodes. Each subsequent node gets base + index."
  type        = number
  default     = 200
}

variable "master_ip_start_offset" {
  description = "Host offset within network_cidr for the first master node (e.g. 101 → .101, .102, …)"
  type        = number
  default     = 101
}

variable "master_cpu_cores" {
  description = "Number of vCPUs allocated to each master node"
  type        = number
  default     = 4
}

variable "master_memory" {
  description = "RAM in MiB allocated to each master node"
  type        = number
  default     = 8192
}

# ==============================================================================
# Kubernetes Workers
# ==============================================================================

variable "worker_count" {
  description = "Number of Kubernetes worker nodes to create. Set to 0 to skip."
  type        = number
  default     = 0
}

variable "worker_vm_id_base" {
  description = "Base VM ID for worker nodes. Each subsequent node gets base + index."
  type        = number
  default     = 300
}

variable "worker_ip_start_offset" {
  description = "Host offset within network_cidr for the first worker node (e.g. 111 → .111, .112, …)"
  type        = number
  default     = 111
}

variable "worker_cpu_cores" {
  description = "Number of vCPUs allocated to each worker node"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "RAM in MiB allocated to each worker node"
  type        = number
  default     = 8192
}

# ==============================================================================
# GPU Nodes
# ==============================================================================

variable "gpu_node_count" {
  description = "Number of GPU passthrough nodes to create. Set to 0 to skip."
  type        = number
  default     = 0
}

variable "gpu_node_vm_id_base" {
  description = "Base VM ID for GPU nodes."
  type        = number
  default     = 400
}

variable "gpu_node_ip_offset" {
  description = "Host offset within network_cidr for the first GPU node (e.g. 121 → .121)"
  type        = number
  default     = 121
}

variable "gpu_node_cpu_cores" {
  description = "Number of vCPUs allocated to each GPU node"
  type        = number
  default     = 8
}

variable "gpu_node_memory" {
  description = "RAM in MiB allocated to each GPU node"
  type        = number
  default     = 16384
}

variable "gpu_node_disk_size" {
  description = "Root disk size in GiB for GPU nodes"
  type        = number
  default     = 50
}

variable "gpu_mapping_name" {
  description = "Name of the Proxmox Resource Mapping for the GPU (Datacenter → Resource Mappings → PCI Devices). Using a mapping avoids the 'only root can set hostpci' error with non-root API tokens."
  type        = string
  default     = "rtx3060"
}

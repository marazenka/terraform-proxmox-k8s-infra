# terraform-proxmox-ubuntu-k8s

OpenTofu / Terraform module that provisions a Kubernetes cluster on Proxmox VE by cloning an Ubuntu cloud-init VM template. Creates optional HAProxy load balancer nodes, configurable master nodes, and configurable worker nodes.

## Requirements

| Tool | Version |
|---|---|
| OpenTofu / Terraform | >= 1.6 |
| bpg/proxmox provider | ~> 0.97 |

A Proxmox VE Ubuntu cloud-init template must exist before running this module.  
See [`create-vm-template.sh`](create-vm-template.sh) for an example of how to build one.

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in your secrets & settings
tofu init
tofu apply
```

## Inputs

| Variable | Description | Default |
|---|---|---|
| `proxmox_endpoint` | Proxmox API URL | — |
| `proxmox_api_token` | API token `user@realm!id=uuid` | — |
| `proxmox_insecure` | Skip TLS verification | `true` |
| `node_name` | Proxmox node name | `pve` |
| `template_vm_id` | Source template VM ID | `9000` |
| `network_cidr` | Subnet for all VMs | `192.168.50.0/24` |
| `network_gateway` | Default gateway | `192.168.50.1` |
| `network_bridge` | Proxmox Linux bridge | `vmbr0` |
| `disk_datastore` | Storage ID for root disks | `local-lvm` |
| `disk_size` | Root disk size (GiB) | `25` |
| `vm_user` | cloud-init OS username | `ubuntu` |
| `ssh_public_key` | SSH public key for VM access | — |
| `haproxy_count` | Number of HAProxy nodes (0 = disabled) | `0` |
| `master_count` | Number of master nodes | `1` |
| `worker_count` | Number of worker nodes (0 = disabled) | `0` |

See [`variables.tf`](variables.tf) for the full list including VM ID bases, IP offsets, CPU, and memory settings.

## Outputs

| Output | Description |
|---|---|
| `haproxy_ips` | IP addresses of HAProxy nodes |
| `master_ips` | IP addresses of master nodes |
| `worker_ips` | IP addresses of worker nodes |
| `cluster_summary` | Node count summary |

## IP Addressing

IPs are computed automatically from `network_cidr` + per-role offset variables using `cidrhost()`.  
Default layout with a `/24`:

| Role | Offset variable | Example IPs |
|---|---|---|
| HAProxy | `haproxy_ip_offset = 100` | .100, .101, … |
| Masters | `master_ip_start_offset = 101` | .101, .102, .103 |
| Workers | `worker_ip_start_offset = 111` | .111, .112, .113 |

## Security

- `proxmox_api_token` and `ssh_public_key` are marked `sensitive` and must be supplied via `terraform.tfvars` — never hardcoded.
- `terraform.tfvars` and `*.tfstate` are listed in [`.gitignore`](.gitignore) and must not be committed.

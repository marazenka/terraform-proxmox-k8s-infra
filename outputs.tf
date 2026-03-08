output "haproxy_ips" {
  description = "IP addresses of HAProxy (load balancer) nodes"
  value = [
    for i in range(var.haproxy_count) :
    cidrhost(var.network_cidr, var.haproxy_ip_offset + i)
  ]
}

output "master_ips" {
  description = "IP addresses of Kubernetes master nodes"
  value = [
    for i in range(var.master_count) :
    cidrhost(var.network_cidr, var.master_ip_start_offset + i)
  ]
}

output "worker_ips" {
  description = "IP addresses of Kubernetes worker nodes"
  value = [
    for i in range(var.worker_count) :
    cidrhost(var.network_cidr, var.worker_ip_start_offset + i)
  ]
}

output "cluster_summary" {
  description = "Quick summary of the provisioned cluster topology"
  value = {
    haproxy_nodes = var.haproxy_count
    master_nodes  = var.master_count
    worker_nodes  = var.worker_count
  }
}

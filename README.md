# terraform-proxmox-ubuntu-k8s

OpenTofu / Terraform module that spins up a set of Ubuntu VMs on Proxmox VE by cloning a cloud-init template. The module itself has no opinion about what runs inside the VMs — it just provisions infrastructure.

The primary use case this was built for is quickly standing up a bare-metal Kubernetes cluster using [k3s-ansible](https://github.com/k3s-io/k3s-ansible). That workflow is described below.

## Requirements

- OpenTofu >= 1.6 (or Terraform >= 1.6)
- [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider `~> 0.97`
- A Proxmox VE Ubuntu cloud-init VM template. See [`create-vm-template.sh`](create-vm-template.sh).

## Provision VMs

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — at minimum set proxmox_endpoint, proxmox_api_token, ssh_public_key
tofu init
tofu apply
```

All variables are documented in [`variables.tf`](variables.tf). The key knobs are node counts (`master_count`, `worker_count`, `haproxy_count`), per-group CPU/RAM/disk, and the network CIDR + IP offsets used to assign static IPs.

## Deploy Kubernetes with k3s-ansible

Once the VMs are up, use [k3s-ansible](https://github.com/k3s-io/k3s-ansible) to install k3s across them.

### 1. Clone k3s-ansible

```bash
git clone https://github.com/k3s-io/k3s-ansible.git
cd k3s-ansible
```

### 2. Set up Ansible

```bash
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install ansible
```

### 3. Configure inventory

```bash
cp inventory-sample.yml inventory.yml
```

Edit `inventory.yml` to match the IPs from `tofu output`.

**1 control node + 2 workers:**

```yaml
k3s_cluster:
  children:
    server:
      hosts:
        192.168.50.101:   # master-1
    agent:
      hosts:
        192.168.50.111:   # worker-1
        192.168.50.112:   # worker-2
  vars:
    ansible_port: 22
    ansible_user: ubuntu
    k3s_version: v1.32.2+k3s1
    token: "changeme!"   # generate with: openssl rand -base64 48
    api_endpoint: "{{ hostvars[groups['server'][0]]['ansible_host'] | default(groups['server'][0]) }}"
```

**Single node** (control plane also schedules workloads — good for home lab):

```yaml
k3s_cluster:
  children:
    server:
      hosts:
        192.168.50.101:
  vars:
    ansible_port: 22
    ansible_user: ubuntu
    k3s_version: v1.32.2+k3s1
    token: "changeme!"   # generate with: openssl rand -base64 48
    api_endpoint: "{{ hostvars[groups['server'][0]]['ansible_host'] | default(groups['server'][0]) }}"
```

### 4. Run the playbook

```bash
ansible-playbook playbooks/site.yml -i inventory.yml
```

After it completes, the kubeconfig is merged into `~/.kube/config` under the `k3s-ansible` context:

```bash
kubectl config use-context k3s-ansible
kubectl get nodes

# smoke test — run a simple nginx pod
kubectl run nginx --image=nginx --port=80
kubectl get pods -w
kubectl delete pod/nginx
```

## Security

- `proxmox_api_token` and `ssh_public_key` are `sensitive` variables — never hardcode them, always pass via `terraform.tfvars`.
- `terraform.tfvars` and `*.tfstate` are in [`.gitignore`](.gitignore) and must not be committed.

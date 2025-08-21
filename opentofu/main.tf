locals {
  k3s_servers = {
    "hlab-k3s-srv-01" = { ip = "10.0.10.50", cpu = 2, memory = 4096 }
    "hlab-k3s-srv-02" = { ip = "10.0.10.51", cpu = 2, memory = 4096 }
    "hlab-k3s-srv-03" = { ip = "10.0.10.52", cpu = 2, memory = 4096 }
  }
}

module "k3s_servers" {
  source   = "./modules/vm"
  for_each = local.k3s_servers
  
  vm_name        = each.key
  vm_description = "K3s Server Nodes running control plane services"
  tags           = ["kubernetes", "control-plane", "ha"]
  node_name      = var.node_name
  cpu_cores      = each.value.cpu
  memory_mb      = each.value.memory
  template_id    = "local:vztmpl/ubuntu-22.04-ansible-template"  # Use Ansible-built template
  disk_size      = 60
  ip_address     = "${each.value.ip}/24"
  gateway        = "192.168.1.1"
}

# Configure K3s servers with Ansible after VM creation
resource "ansible_playbook" "k3s_servers" {
  depends_on = [module.k3s_servers]
  
  playbook   = "../ansible/playbooks/k3s-servers.yml"
  name       = "k3s-servers"
  replayable = true

  extra_vars = {
    k3s_cluster_token = "secure-k3s-token-change-me"
  }

  # Ensure VMs are accessible before running playbook
  ansible_playbook_binary = "ansible-playbook"
}

# Example 2: Kubernetes worker nodes with different specs
locals {
  k8s_workers = {
    "hlab-k3s-wkr-01" = { ip = "192.168.1.120", cpu = 4, memory = 8192, disk = 100 }
    "hlab-k3s-wkr-02" = { ip = "192.168.1.121", cpu = 4, memory = 8192, disk = 100 }
    "hlab-k3s-wkr-03" = { ip = "192.168.1.122", cpu = 6, memory = 16384, disk = 200 } # Larger worker
  }
}

module "k8s_workers" {
  source   = "./modules/vm"
  for_each = local.k8s_workers
  
  vm_name        = each.key
  vm_description = "Kubernetes worker node ${each.key}"
  tags           = ["kubernetes", "worker"]
  node_name      = var.node_name
  cpu_cores      = each.value.cpu
  memory_mb      = each.value.memory
  template_id    = "local:vztmpl/ubuntu-22.04-ansible-template"  # Use Ansible-built template
  disk_size      = each.value.disk
  ip_address     = "${each.value.ip}/24"
  gateway        = "192.168.1.1"
}

# Configure K3s workers with Ansible after VM creation
resource "ansible_playbook" "k3s_workers" {
  depends_on = [module.k8s_workers, ansible_playbook.k3s_servers]
  
  playbook   = "../ansible/playbooks/k3s-workers.yml"
  name       = "k3s-workers"
  replayable = true

  extra_vars = {
    k3s_cluster_token = "secure-k3s-token-change-me"
  }

  ansible_playbook_binary = "ansible-playbook"
}

# Example 3: Docker Swarm nodes
locals {
  docker_swarm_nodes = {
    "hlab-swarm-mgr-01" = { ip = "192.168.1.130", role = "manager", cpu = 2, memory = 4096 }
    "hlab-swarm-mgr-02" = { ip = "192.168.1.131", role = "manager", cpu = 2, memory = 4096 }
    "hlab-swarm-wkr-01" = { ip = "192.168.1.135", role = "worker", cpu = 4, memory = 8192 }
    "hlab-swarm-wkr-02" = { ip = "192.168.1.136", role = "worker", cpu = 4, memory = 8192 }
  }
}

module "docker_swarm" {
  source   = "./modules/vm"
  for_each = local.docker_swarm_nodes
  
  vm_name        = each.key
  vm_description = "Docker Swarm ${each.value.role} node"
  tags           = ["docker", "swarm", each.value.role]
  node_name      = var.node_name
  cpu_cores      = each.value.cpu
  memory_mb      = each.value.memory
  template_id    = "local:iso/ubuntu-22.04-server-cloudimg-amd64.img"
  disk_size      = 50
  ip_address     = "${each.value.ip}/24"
  gateway        = "192.168.1.1"
}

# Example 4: Media services cluster
locals {
  media_services = {
    "hlab-plex-01"     = { ip = "192.168.1.140", service = "plex", cpu = 4, memory = 8192, disk = 100 }
    "hlab-jellyfin-01" = { ip = "192.168.1.141", service = "jellyfin", cpu = 4, memory = 6144, disk = 80 }
    "hlab-arr-01"      = { ip = "192.168.1.142", service = "arr-stack", cpu = 2, memory = 4096, disk = 60 }
  }
}

module "media_services" {
  source   = "./modules/vm"
  for_each = local.media_services
  
  vm_name        = each.key
  vm_description = "${each.value.service} media service"
  tags           = ["media", each.value.service]
  node_name      = var.node_name
  cpu_cores      = each.value.cpu
  memory_mb      = each.value.memory
  template_id    = "local:iso/ubuntu-22.04-server-cloudimg-amd64.img"
  disk_size      = each.value.disk
  ip_address     = "${each.value.ip}/24"
  gateway        = "192.168.1.1"
}

# Example 5: Development environment VMs
locals {
  dev_environments = toset([
    "hlab-dev-python",
    "hlab-dev-nodejs", 
    "hlab-dev-golang"
  ])
}

module "dev_environments" {
  source   = "./modules/vm"
  for_each = local.dev_environments
  
  vm_name        = each.value
  vm_description = "Development environment for ${split("-", each.value)[2]}"
  tags           = ["development", split("-", each.value)[2]]
  node_name      = var.node_name
  cpu_cores      = 2
  memory_mb      = 4096
  template_id    = "local:iso/ubuntu-22.04-server-cloudimg-amd64.img"
  disk_size      = 40
  ip_address     = "dhcp" # Use DHCP for dev environments
  gateway        = "192.168.1.1"
}

# Example 6: Database cluster with replication
locals {
  database_cluster = {
    "hlab-db-primary-01"   = { ip = "192.168.1.150", role = "primary", cpu = 4, memory = 8192 }
    "hlab-db-replica-01"   = { ip = "192.168.1.151", role = "replica", cpu = 2, memory = 4096 }
    "hlab-db-replica-02"   = { ip = "192.168.1.152", role = "replica", cpu = 2, memory = 4096 }
  }
}

module "database_cluster" {
  source   = "./modules/vm"
  for_each = local.database_cluster
  
  vm_name        = each.key
  vm_description = "Database ${each.value.role} node"
  tags           = ["database", "postgresql", each.value.role]
  node_name      = var.node_name
  cpu_cores      = each.value.cpu
  memory_mb      = each.value.memory
  template_id    = "local:iso/ubuntu-22.04-server-cloudimg-amd64.img"
  disk_size      = 100
  ip_address     = "${each.value.ip}/24"
  gateway        = "192.168.1.1"
}

# =============================================================================
# OUTPUTS - Get information about created VMs
# =============================================================================

# Output Kubernetes control plane IPs
output "k8s_control_plane_ips" {
  description = "IP addresses of Kubernetes control plane nodes"
  value = {
    for name, vm in module.k8s_control_planes : name => vm.vm_ipv4_address
  }
}

# Output Kubernetes worker IPs  
output "k8s_worker_ips" {
  description = "IP addresses of Kubernetes worker nodes"
  value = {
    for name, vm in module.k8s_workers : name => vm.vm_ipv4_address
  }
}

# Output Docker Swarm node information
output "docker_swarm_nodes" {
  description = "Docker Swarm node information"
  value = {
    for name, vm in module.docker_swarm : name => {
      id   = vm.vm_id
      role = local.docker_swarm_nodes[name].role
      ip   = vm.vm_ipv4_address
    }
  }
}

# Media server (Plex, Jellyfin, etc.) - Single VM example
# module "media_server" {
#   source = "./modules/vm"
#   
#   vm_name        = "media-server"
#   vm_description = "Media streaming server"
#   tags           = ["media", "entertainment"]
#   node_name      = var.node_name
#   cpu_cores      = 4
#   memory_mb      = 4096
#   template_id    = "local:iso/ubuntu-22.04-server-cloudimg-amd64.img"
#   disk_size      = 100
#   ip_address     = "192.168.1.120/24"
#   gateway        = "192.168.1.1"
# }

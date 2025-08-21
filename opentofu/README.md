# OpenTofu Configuration

This directory contains the OpenTofu configuration for managing Proxmox VMs with Ansible post-deployment configuration.

## Structure

```
opentofu/
├── main.tf                      # Main infrastructure definitions
├── providers.tf                 # Provider configuration (Proxmox + Ansible)
├── variables.tf                 # Variable definitions
├── terraform.tfvars.example     # Example variables file
└── modules/
    └── vm/                      # Reusable VM module
        ├── main.tf              # VM resource definition
        ├── variables.tf         # Module variables
        └── outputs.tf           # Module outputs
```

## Usage

### Initial Setup

1. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with your Proxmox credentials and settings
   ```

2. **Initialize OpenTofu**:
   ```bash
   cd opentofu
   tofu init
   ```

3. **Plan and apply**:
   ```bash
   tofu plan
   tofu apply
   ```

### Working Directory

All OpenTofu commands should be run from the `opentofu/` directory:

```bash
cd opentofu
tofu plan
tofu apply
tofu destroy
```

## Configuration

### Provider Configuration

The configuration uses two providers:
- **Proxmox**: For VM management
- **Ansible**: For post-deployment configuration

### VM Module

The `modules/vm` directory contains a reusable module for creating VMs with:
- Configurable CPU, memory, and disk
- Network configuration
- Template-based deployment
- Cloud-init integration

### Ansible Integration

After VM deployment, Ansible playbooks automatically configure:
- K3s server and worker nodes
- Docker Swarm clusters
- Service-specific configurations

## Variables

Key variables to configure in `terraform.tfvars`:

```hcl
# Proxmox connection
proxmox_endpoint = "https://your-proxmox-ip:8006/api2/json"
proxmox_username = "root@pam"
proxmox_password = "your-password"
node_name        = "your-node-name"

# Template configuration
ubuntu_template_name = "ubuntu-22.04-ansible-template"
template_storage     = "local"
```

## Examples

### Current Configuration

The main.tf includes examples for:
- **K3s Servers**: High-availability control plane nodes
- **K3s Workers**: Worker nodes with different specifications
- **Automatic Configuration**: Ansible playbooks run post-deployment

### Adding New VMs

To add new VM types, follow this pattern:

```hcl
locals {
  my_servers = {
    "server-01" = { ip = "192.168.1.100", cpu = 2, memory = 4096 }
    "server-02" = { ip = "192.168.1.101", cpu = 4, memory = 8192 }
  }
}

module "my_servers" {
  source   = "./modules/vm"
  for_each = local.my_servers
  
  vm_name     = each.key
  template_id = "local:vztmpl/ubuntu-22.04-ansible-template"
  # ... other configuration
}

# Optional: Ansible configuration
resource "ansible_playbook" "my_servers" {
  depends_on = [module.my_servers]
  playbook   = "../ansible/playbooks/my-service.yml"
  name       = "my-servers"
  replayable = true
}
```

## Outputs

The configuration provides outputs for:
- VM IDs and names
- IP addresses
- Cluster information for Kubernetes and Docker Swarm

## Best Practices

1. **Version Control**: Commit changes before applying
2. **State Management**: Use remote state for team environments
3. **Planning**: Always run `tofu plan` before `tofu apply`
4. **Resource Naming**: Use consistent naming conventions
5. **Module Usage**: Leverage the VM module for consistency

## Troubleshooting

### Common Issues

1. **Provider initialization**: Run `tofu init` after adding new providers
2. **State conflicts**: Use `tofu refresh` to sync state
3. **Ansible connectivity**: Ensure SSH keys are properly configured
4. **Template references**: Verify template names match Packer builds

### Debug Commands

```bash
# Validate configuration
tofu validate

# Plan with detailed output
tofu plan -detailed-exitcode

# Apply with logging
TF_LOG=DEBUG tofu apply

# Check state
tofu show
tofu state list
```

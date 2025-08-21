# Automation-Platform

Infrastructure as Code (IaC) repository for managing Proxmox homelab deployments using OpenTofu, Packer, and Ansible.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Packer      │───▶│    Template     │───▶│    OpenTofu     │
│  + Ansible      │    │   (with tools   │    │   + Ansible     │
│  Provisioning   │    │   pre-installed)│    │  Configuration  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

- OpenTofu installed (version 1.8.0 or later)
- Packer installed (version 1.10.0 or later)  
- Ansible installed (version 2.12 or later)
- Access to Proxmox VE server
- API credentials for Proxmox

## Quick Start

### Option 1: Interactive Deployment Script (Recommended)

```bash
git clone <this-repo>
cd Automation-Platform
./deploy.sh
```

The interactive script will guide you through:
1. Prerequisites checking
2. Template building
3. Infrastructure deployment

### Option 2: Manual Steps

1. **Clone and setup**:
   ```bash
   git clone <this-repo>
   cd Automation-Platform
   ```

2. **Configure credentials**:
   ```bash
   # Packer credentials
   cp packer/packer.pkrvars.hcl.example packer/packer.pkrvars.hcl
   # Edit with your Proxmox details
   
   # OpenTofu credentials  
   cp opentofu/terraform.tfvars.example opentofu/terraform.tfvars
   # Edit with your Proxmox details
   ```

3. **Build templates with Packer + Ansible**:
   ```bash
   ./build-template.sh
   ```

4. **Deploy infrastructure with OpenTofu + Ansible**:
   ```bash
   cd opentofu
   tofu init
   tofu plan
   tofu apply
   ```

## Project Organization

This project follows a modular structure with separate directories for each tool:

### 📁 **opentofu/** - Infrastructure as Code
- Contains all OpenTofu/Terraform configuration files
- VM modules and resource definitions
- Provider configurations for Proxmox and Ansible
- **Run all `tofu` commands from this directory**

### 📁 **packer/** - Template Building
- Packer configuration for building VM templates
- Ansible-based provisioning (shell scripts removed)
- Cloud-init configurations for automated installs

### 📁 **ansible/** - Configuration Management
- Playbooks for both Packer template building and post-deployment
- Inventory management for deployed VMs
- Service-specific configurations (K3s, Docker Swarm)

### 📁 Root Directory - Orchestration
- `deploy.sh` - Interactive deployment script
- `build-template.sh` - Template building automation
- Documentation and version constraints

```
├── .tofu-version              # OpenTofu version constraint
├── build-template.sh          # Automated Packer build script
├── opentofu/                  # OpenTofu configuration
│   ├── main.tf               # Main infrastructure definitions
│   ├── providers.tf           # Provider configuration (Proxmox + Ansible)
│   ├── variables.tf           # Global variables
│   ├── terraform.tfvars.example # Example configuration
│   ├── README.md             # OpenTofu-specific documentation
│   └── modules/
│       └── vm/               # Reusable VM module
├── packer/                   # Packer template definitions
│   ├── ubuntu-22.04-ansible.pkr.hcl   # Ansible-enhanced template  
│   ├── packer.pkrvars.hcl.example     # Packer variables template
│   ├── http/                          # Cloud-init autoinstall files
│   └── README.md                      # Packer-specific documentation
├── ansible/                  # Ansible configuration
│   ├── ansible.cfg           # Ansible configuration
│   ├── inventory/            # Dynamic inventory
│   ├── playbooks/           # Ansible playbooks
│   ├── templates/           # Jinja2 templates
│   └── README.md           # Detailed Ansible documentation
└── README.md                # This file
```

## Configuration

### Provider Setup

The Proxmox provider is configured in `providers.tf`. You'll need to set the following variables in `terraform.tfvars`:

- `proxmox_endpoint`: Your Proxmox API endpoint (e.g., `https://192.168.1.100:8006/api2/json`)
- `proxmox_username`: Username for API access (e.g., `root@pam`)
- `proxmox_password`: Password for API access
- `node_name`: Name of your Proxmox node

### VM Module

The `modules/vm` directory contains a reusable module for creating VMs with the following features:

- Configurable CPU cores and memory
- Disk sizing and datastore selection
- Network configuration with static IP support
- Cloud-init integration
- Tagging support

### Example Deployments

The `main.tf` file includes commented examples for common homelab services:

- Docker host for containerized services
- Kubernetes master node
- Media server (Plex, Jellyfin, etc.)

Uncomment and modify these examples to match your needs.

## Usage Examples

### Creating a Simple VM

```hcl
module "test_vm" {
  source = "./modules/vm"
  
  vm_name        = "test-server"
  vm_description = "Test Ubuntu server"
  tags           = ["testing"]
  node_name      = var.node_name
  cpu_cores      = 2
  memory_mb      = 2048
  template_id    = "local:iso/ubuntu-22.04-server-cloudimg-amd64.img"
  disk_size      = 20
  ip_address     = "192.168.1.200/24"
  gateway        = "192.168.1.1"
}
```

### Creating Multiple VMs

```hcl
module "worker_nodes" {
  source = "./modules/vm"
  count  = 3
  
  vm_name        = "worker-${count.index + 1}"
  vm_description = "Kubernetes worker node ${count.index + 1}"
  tags           = ["kubernetes", "worker"]
  node_name      = var.node_name
  cpu_cores      = 2
  memory_mb      = 4096
  template_id    = "local:iso/ubuntu-22.04-server-cloudimg-amd64.img"
  disk_size      = 30
  ip_address     = "192.168.1.${130 + count.index}/24"
  gateway        = "192.168.1.1"
}
```

## Security Notes

- The `terraform.tfvars` file is gitignored to prevent credential exposure
- Use strong passwords and consider API tokens instead of root passwords
- Review firewall rules and network segmentation
- Keep templates and cloud-init files updated

## Troubleshooting

### Common Issues

1. **Authentication errors**: Verify credentials and API access
2. **Template not found**: Ensure template IDs match available images
3. **Network issues**: Check bridge names and IP ranges
4. **Resource conflicts**: Verify VM names and IDs are unique

### Useful Commands

```bash
# Check OpenTofu version
tofu version

# Validate configuration
tofu validate

# Plan changes
tofu plan

# Apply changes
tofu apply

# Destroy resources (use with caution)
tofu destroy

# Show current state
tofu show
```

## Contributing

When adding new modules or configurations:

1. Follow OpenTofu best practices
2. Use descriptive variable names and documentation
3. Include examples in comments
4. Test changes in a development environment first
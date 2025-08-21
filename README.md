# Automation Platform - Multi-Distribution IaC for Proxmox

A comprehensive Infrastructure as Code (IaC) platform for managing Proxmox deployments using OpenTofu, Packer, and Ansible. This platform supports multiple Linux distributions and provides automated template building, infrastructure provisioning, and configuration management.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Packer      │───▶│    Template     │───▶│    OpenTofu     │
│  + Ansible      │    │   (with tools   │    │   + Ansible     │
│  Provisioning   │    │   pre-installed)│    │  Configuration  │
└─────────────────┘    └─────────────────┘    └─────────────────┘

Automation-Platform/
├── opentofu/          # Infrastructure provisioning with OpenTofu
├── packer/            # VM template building with Packer
├── ansible/           # Configuration management with Ansible
├── build-template.sh  # Interactive template builder
└── deploy.sh         # Deployment orchestration
```

## 🔧 Prerequisites

- **Proxmox VE** 7.x or 8.x with API access
- **OpenTofu/Terraform** 1.8.0+
- **Packer** 1.10.0+
- **Ansible** 2.12+
- **Git** (for repository management)

## 🚀 Quick Start

### Option 1: Interactive Deployment (Recommended)

```bash
git clone <your-repo-url>
cd Automation-Platform
./deploy.sh
```

The interactive script guides you through:
1. Prerequisites checking
2. Template building
3. Infrastructure deployment

### Option 2: Manual Steps

1. **Clone and Setup**
   ```bash
   git clone <your-repo-url>
   cd Automation-Platform
   ```

2. **Configure Packer Variables**
   ```bash
   cp packer/packer.pkrvars.hcl.example packer/packer.pkrvars.hcl
   # Edit with your Proxmox credentials and settings
   ```

3. **Configure OpenTofu Variables**
   ```bash
   cp opentofu/terraform.tfvars.example opentofu/terraform.tfvars
   # Edit with your infrastructure requirements
   ```

4. **Build VM Templates**
   ```bash
   ./build-template.sh
   # Select from available distributions
   ```

5. **Deploy Infrastructure**
   ```bash
   cd opentofu
   tofu init
   tofu plan
   tofu apply
   ```

## 📦 Supported Linux Distributions

### Production-Ready Distributions
- **Ubuntu 22.04 LTS** - Long-term support, battle-tested
- **Rocky Linux 9** - RHEL-compatible enterprise Linux
- **Debian 12 (Bookworm)** - Stable release

### Latest/Testing Distributions
- **Ubuntu 24.04.3 LTS** - Latest LTS with newest features
- **Rocky Linux 10** - Latest RHEL-compatible (may be beta/RC)
- **Debian 13 (Trixie)** - Testing branch (may be unstable)

## 🏗️ Component Details

### Packer Templates
Each distribution includes:
- **Automated Installation**: Cloud-init (Ubuntu), Kickstart (Rocky), Preseed (Debian)
- **Ansible Provisioning**: Base system setup, Docker, Kubernetes (K3s)
- **Security Hardening**: SSH key authentication, firewall configuration
- **Cloud-Init Ready**: Supports post-deployment customization

### OpenTofu Infrastructure
- **Modular VM Module**: Reusable VM definitions with configurable resources
- **Provider Configuration**: Proxmox and Ansible providers
- **K3s Cluster Support**: Automated Kubernetes cluster deployment
- **Post-Deployment Ansible**: Automatic configuration management

### Ansible Playbooks
- **Cross-Platform Support**: OS family detection and conditional logic
- **Base System Setup**: User management, SSH hardening, essential packages
- **Container Platform**: Docker installation and configuration
- **Kubernetes Platform**: K3s cluster setup (server/agent modes)
- **Multi-OS Package Management**: APT (Debian/Ubuntu), DNF (Rocky/RHEL)

## 📋 Usage Examples

### Building Specific Templates

```bash
# Interactive menu
./build-template.sh

# Direct Packer commands
packer build -var-file="packer/packer.pkrvars.hcl" packer/ubuntu-24.04.3-ansible.pkr.hcl
packer build -var-file="packer/packer.pkrvars.hcl" packer/rocky-10-ansible.pkr.hcl
packer build -var-file="packer/packer.pkrvars.hcl" packer/debian-13-ansible.pkr.hcl
```

### Deploying Infrastructure

```bash
# Full deployment with template building
./deploy.sh

# OpenTofu-only deployment
cd opentofu
tofu init
tofu plan
tofu apply
```

### Manual Ansible Configuration

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/docker-swarm.yml
ansible-playbook -i inventory/hosts.yml playbooks/k3s-servers.yml
ansible-playbook -i inventory/hosts.yml playbooks/k3s-workers.yml
```

## ⚙️ Configuration Guide

### Packer Configuration (packer.pkrvars.hcl)
```hcl
# Proxmox connection
proxmox_node = "pve-node1"
proxmox_url = "https://proxmox.example.com:8006/api2/json"
proxmox_username = "user@pam"
proxmox_password = "secure-password"
proxmox_token_id = "automation@pam!mytoken"
proxmox_token_secret = "uuid-token-secret"

# VM specifications
vm_cpu_cores = 2
vm_memory = 2048
vm_disk_size = "20G"
vm_storage = "local-lvm"
vm_network_bridge = "vmbr0"

# SSH configuration
ssh_username = "ansible"
ssh_public_key_file = "~/.ssh/id_rsa.pub"
```

### OpenTofu Configuration (terraform.tfvars)
```hcl
# Proxmox settings
proxmox_url = "https://proxmox.example.com:8006"
proxmox_username = "user@pam"
proxmox_password = "secure-password"

# Infrastructure settings
node_name = "pve-node1"
template_name = "ubuntu-24.04.3-ansible-template"
storage_pool = "local-lvm"

# K3s cluster configuration
k3s_servers = [
  {
    name = "k3s-server-1"
    ip = "10.0.1.10"
    cores = 4
    memory = 4096
  }
]

k3s_workers = [
  {
    name = "k3s-worker-1"
    ip = "10.0.1.20"
    cores = 2
    memory = 2048
  }
]
```

## 🔧 Advanced Configuration

### Custom Ansible Variables
Create `ansible/group_vars/all.yml`:
```yaml
# Global settings
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa

# Docker configuration
docker_users:
  - ansible
  - admin

# K3s configuration
k3s_version: v1.28.5+k3s1
k3s_server_init_args:
  - --write-kubeconfig-mode=644
  - --cluster-cidr=10.42.0.0/16
  - --service-cidr=10.43.0.0/16

# Security settings
ssh_port: 22
ssh_password_authentication: false
ufw_enabled: true
firewalld_enabled: true  # For Rocky Linux
```

### Distribution-Specific Settings
Create `ansible/group_vars/rocky.yml`:
```yaml
# Rocky Linux specific
os_family: RedHat
package_manager: dnf
firewall_service: firewalld
python_package: python3
```

## 📁 Project Structure

```
├── .tofu-version              # OpenTofu version constraint
├── build-template.sh          # Interactive template builder
├── deploy.sh                  # Deployment orchestration
├── opentofu/                  # Infrastructure provisioning
│   ├── main.tf               # Main infrastructure definitions
│   ├── providers.tf           # Provider configuration (Proxmox + Ansible)
│   ├── variables.tf           # Global variables
│   ├── terraform.tfvars.example # Example configuration
│   ├── README.md             # OpenTofu-specific documentation
│   └── modules/
│       └── vm/               # Reusable VM module
├── packer/                   # Template building
│   ├── *.pkr.hcl             # Multiple distribution templates
│   ├── packer.pkrvars.hcl.example # Example configuration
│   ├── http/                 # Auto-install configurations
│   │   ├── debian/           # Preseed files
│   │   ├── rocky/            # Kickstart files
│   │   └── ubuntu/           # Cloud-init files
│   └── README.md             # Packer-specific documentation
├── ansible/                  # Configuration management
│   ├── ansible.cfg           # Ansible configuration
│   ├── inventory/            # Dynamic inventory
│   ├── playbooks/           # Multi-OS playbooks
│   ├── templates/           # K3s service templates
│   └── README.md           # Ansible documentation
└── README.md                # This file
```

## 🐛 Troubleshooting

### Common Issues

1. **Packer Build Failures**
   ```bash
   # Enable debug logging
   PACKER_LOG=1 packer build -var-file="packer/packer.pkrvars.hcl" template.pkr.hcl
   ```

2. **ISO Download Issues**
   - Verify internet connectivity
   - Check ISO URLs in Packer templates
   - Consider using local ISO files

3. **Proxmox API Authentication**
   ```bash
   # Test API connectivity
   curl -k -d "username=user@pam&password=password" \
        https://proxmox.example.com:8006/api2/json/access/ticket
   ```

4. **Ansible Connection Issues**
   ```bash
   # Test Ansible connectivity
   ansible all -i inventory/hosts.yml -m ping
   ```

### Distribution-Specific Notes

- **Rocky Linux 10**: May be in beta/RC status - test thoroughly
- **Debian 13**: Testing branch - expect occasional instability
- **Ubuntu 24.04.3**: Latest LTS - generally stable but newer packages

### Useful Commands

```bash
# OpenTofu operations
tofu version
tofu validate
tofu plan
tofu apply
tofu show

# Packer operations
packer validate template.pkr.hcl
packer build template.pkr.hcl

# Ansible operations
ansible-playbook --check playbook.yml
ansible-inventory --list
ansible all -m ping
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-distro`
3. Test your changes thoroughly
4. Submit a pull request with detailed description

## 📄 Security Considerations

- The `terraform.tfvars` and `packer.pkrvars.hcl` files are gitignored to prevent credential exposure
- Use strong passwords and consider API tokens instead of root passwords
- Review firewall rules and network segmentation
- Keep templates and cloud-init files updated
- SSH key authentication is enforced by default

## 📊 Template Status

| Distribution | Status | Last Updated | Ansible Support | Notes |
|-------------|--------|--------------|-----------------|-------|
| Ubuntu 22.04 LTS | ✅ Stable | Latest | ✅ Full | Production ready |
| Ubuntu 24.04.3 LTS | ✅ Stable | Latest | ✅ Full | Latest LTS |
| Rocky Linux 9 | ✅ Stable | Latest | ✅ Full | Enterprise ready |
| Rocky Linux 10 | ⚠️ Beta | Latest | ✅ Full | May be beta/RC |
| Debian 12 | ✅ Stable | Latest | ✅ Full | Production ready |
| Debian 13 | ⚠️ Testing | Latest | ✅ Full | May be unstable |

**Legend**: ✅ Stable, ⚠️ Caution Advised, ❌ Not Ready

## 🔗 References

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Packer Documentation](https://www.packer.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Proxmox VE API Documentation](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [K3s Documentation](https://docs.k3s.io/)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
# Packer Integration for Proxmox Templates

This directory contains Packer configurations for building custom VM templates that can be consumed by OpenTofu.

## Directory Structure

```
packer/
├── ubuntu-22.04-ansible.pkr.hcl  # Ansible-enhanced Packer configuration
├── packer.pkrvars.hcl.example    # Variables template
├── http/                         # Cloud-init files for autoinstall
│   ├── user-data                 # Ubuntu autoinstall configuration
│   └── meta-data                 # Cloud-init metadata
└── README.md                     # This documentation
```

Note: Shell scripts have been removed in favor of Ansible provisioning for better maintainability and consistency.

## Prerequisites

1. **Install Packer**: Download from [packer.io](https://www.packer.io/downloads)
2. **Proxmox Access**: Ensure you have API access to your Proxmox server
3. **Network Access**: Packer needs to reach your Proxmox server and the internet

## Quick Start

1. **Configure credentials**:
   ```bash
   cp packer/packer.pkrvars.hcl.example packer/packer.pkrvars.hcl
   # Edit with your Proxmox details
   ```

2. **Build template**:
   ```bash
   ./build-template.sh
   ```

## Template Features

The Ubuntu 22.04 template includes:

### Base System
- Ubuntu 22.04 LTS Server
- Cloud-init configured for Proxmox
- QEMU Guest Agent
- Automatic security updates
- SSH server with key authentication

### Container Runtime
- Docker Engine with Docker Compose
- Containerd runtime
- User added to docker group

### Kubernetes Tools
- kubelet, kubeadm, kubectl (v1.28)
- Helm package manager
- crictl (Container Runtime Interface CLI)
- k9s (Kubernetes CLI manager)
- Containerd configured for Kubernetes

### System Utilities
- htop, iotop, iftop, ncdu, tree
- jq, yq for JSON/YAML processing
- Network tools (nmap, tcpdump, dnsutils)
- Security tools (fail2ban, ufw)
- Development tools (git, vim, tmux)
- Oh My Zsh for improved shell experience

### Security & Monitoring
- UFW firewall (configured but not restrictive)
- fail2ban for intrusion prevention
- Log rotation configured
- NTP synchronization

## Using Templates in OpenTofu

After building with Packer, reference the template in your OpenTofu configuration:

```hcl
module "my_vm" {
  source = "./modules/vm"
  
  vm_name     = "my-server"
  template_id = "local:vztmpl/ubuntu-22.04-template"  # Packer-built template
  # ... other configuration
}
```

## Build Process

The Packer build process:

1. **Download Ubuntu ISO**: Fetches Ubuntu 22.04 LTS Server ISO
2. **Create VM**: Boots VM in Proxmox with autoinstall
3. **Wait for Installation**: Uses cloud-init for automated setup
4. **Provision Software**: Runs installation scripts
5. **Configure System**: Prepares template for cloud-init usage
6. **Cleanup**: Removes logs, caches, and sensitive data
7. **Create Template**: Converts VM to reusable template

## Customization

### Adding Software
Create additional scripts in `packer/scripts/` and reference them in the build block:

```hcl
provisioner "shell" {
  script = "packer/scripts/install-my-software.sh"
}
```

### Modifying Cloud-Init
Edit `packer/http/user-data` to change:
- Default user configuration
- Package installation
- Network settings
- Storage layout

### Template Variants
Create new `.pkr.hcl` files for different distributions or use cases:
- `debian-12-ansible.pkr.hcl` for Debian with Ansible
- `rocky-9-ansible.pkr.hcl` for Rocky Linux with Ansible
- `windows-server-ansible.pkr.hcl` for Windows with Ansible (if supported)

## Best Practices

1. **Version Control**: Tag your templates with build dates/versions
2. **Security**: Regularly rebuild templates with latest security updates
3. **Testing**: Test templates thoroughly before using in production
4. **Documentation**: Document any customizations made to templates
5. **Automation**: Consider automating template builds with CI/CD

## Troubleshooting

### Common Issues

1. **Network timeout**: Ensure Packer can reach Proxmox API and internet
2. **SSH connection failed**: Check SSH configuration and user credentials
3. **Provisioning failed**: Review script logs and dependencies
4. **Template not found**: Verify template was created successfully in Proxmox

### Debug Mode
Run Packer with debug flag for detailed output:
```bash
PACKER_LOG=1 packer build -var-file="packer/packer.pkrvars.hcl" packer/
```

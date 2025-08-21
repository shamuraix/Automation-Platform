# Multi-Distribution Deployment Guide

## 🎯 Overview

This guide walks you through deploying your multi-distribution Automation Platform. You now have support for 6 different Linux distributions with Ansible-based provisioning.

## 📋 Pre-Deployment Checklist

### ✅ Prerequisites Verification
- [ ] Proxmox VE 7.x or 8.x accessible
- [ ] OpenTofu 1.8.0+ installed
- [ ] Packer 1.10.0+ installed
- [ ] Ansible 2.12+ installed
- [ ] SSH key pair generated (`~/.ssh/id_rsa`)

### ✅ Configuration Files
- [ ] `packer/packer.pkrvars.hcl` configured
- [ ] `opentofu/terraform.tfvars` configured
- [ ] Network settings verified (IP ranges, gateways)

## 🚀 Deployment Scenarios

### Scenario 1: Production Homelab (Recommended)
**Best for**: Stable, reliable homelab environment

**Recommended Distributions**:
- Ubuntu 22.04 LTS (primary)
- Rocky Linux 9 (enterprise workloads)
- Debian 12 (minimal footprint)

```bash
# Build production-ready templates
./build-template.sh
# Select options 1, 3, 5

# Deploy with stable templates
cd opentofu
tofu apply
```

### Scenario 2: Cutting-Edge Testing
**Best for**: Testing latest features and bleeding-edge software

**Recommended Distributions**:
- Ubuntu 24.04.3 LTS (latest LTS)
- Rocky Linux 10 (latest enterprise)
- Debian 13 (testing branch)

```bash
# Build latest templates
./build-template.sh
# Select options 2, 4, 6

# Test thoroughly before production
cd opentofu
tofu plan  # Review changes carefully
tofu apply
```

### Scenario 3: Mixed Environment
**Best for**: Development and testing with multiple OS families

```bash
# Build all templates
./build-template.sh
# Select option 7 (Build All)

# Deploy different workloads on different OS
# Edit main.tf to specify template per VM
```

## 🔧 Step-by-Step Deployment

### Step 1: Template Selection and Building

#### Option A: Interactive Selection
```bash
./build-template.sh
```
Choose your distribution(s) from the menu.

#### Option B: Direct Building
```bash
# Ubuntu 24.04.3 LTS (recommended for new deployments)
packer build -var-file="packer/packer.pkrvars.hcl" packer/ubuntu-24.04.3-ansible.pkr.hcl

# Rocky Linux 9 (enterprise stable)
packer build -var-file="packer/packer.pkrvars.hcl" packer/rocky-9-ansible.pkr.hcl

# Debian 12 (lightweight option)
packer build -var-file="packer/packer.pkrvars.hcl" packer/debian-12-ansible.pkr.hcl
```

### Step 2: Infrastructure Deployment

```bash
cd opentofu

# Initialize providers
tofu init

# Review planned changes
tofu plan

# Apply infrastructure
tofu apply
```

### Step 3: Post-Deployment Verification

```bash
# Test Ansible connectivity
cd ../ansible
ansible all -i inventory/hosts.yml -m ping

# Check service status
ansible-playbook -i inventory/hosts.yml playbooks/docker-swarm.yml --check
ansible-playbook -i inventory/hosts.yml playbooks/k3s-servers.yml --check
```

## 🎛️ Template Configuration Matrix

| Distribution | Template Name | Use Case | Stability | Resource Req |
|-------------|---------------|----------|-----------|--------------|
| Ubuntu 22.04 LTS | `ubuntu-22.04-ansible` | Production servers | 🟢 Stable | Low-Medium |
| Ubuntu 24.04.3 LTS | `ubuntu-24.04.3-ansible` | Latest LTS features | 🟢 Stable | Low-Medium |
| Rocky Linux 9 | `rocky-9-ansible` | Enterprise workloads | 🟢 Stable | Medium |
| Rocky Linux 10 | `rocky-10-ansible` | Latest enterprise | 🟡 Beta/RC | Medium |
| Debian 12 | `debian-12-ansible` | Minimal systems | 🟢 Stable | Low |
| Debian 13 | `debian-13-ansible` | Testing/Development | 🟡 Testing | Low |

## 🔍 Distribution-Specific Notes

### Ubuntu Distributions
- **22.04 LTS**: Proven stability, 5-year support lifecycle
- **24.04.3 LTS**: Latest hardware support, newer kernel versions
- **Package Manager**: APT with `apt` commands
- **Firewall**: UFW (Uncomplicated Firewall)
- **Init System**: systemd

### Rocky Linux Distributions
- **Rocky 9**: RHEL 9 compatible, enterprise-grade stability
- **Rocky 10**: Latest RHEL features, may be in beta/RC phase
- **Package Manager**: DNF (Dandified YUM)
- **Firewall**: firewalld
- **Init System**: systemd

### Debian Distributions
- **Debian 12 (Bookworm)**: Stable release, minimal footprint
- **Debian 13 (Trixie)**: Testing branch, newest packages but potential instability
- **Package Manager**: APT with `apt` commands
- **Firewall**: UFW (can be installed)
- **Init System**: systemd

## 🛠️ Troubleshooting by Distribution

### Ubuntu Issues
```bash
# Check cloud-init status
cloud-init status

# Review cloud-init logs
sudo journalctl -u cloud-init

# Network configuration
sudo netplan apply
```

### Rocky Linux Issues
```bash
# Check kickstart installation logs
sudo journalctl -u anaconda

# SELinux troubleshooting
sudo sealert -a /var/log/audit/audit.log

# Network configuration
sudo nmcli connection reload
```

### Debian Issues
```bash
# Check preseed installation
sudo journalctl -u installer

# Network configuration
sudo systemctl restart networking

# Package issues
sudo apt --fix-broken install
```

## 📊 Performance Recommendations

### Resource Allocation by Use Case

#### Docker Swarm Node
- **CPU**: 2-4 cores
- **Memory**: 4-8 GB
- **Storage**: 50-100 GB
- **Best Distros**: Ubuntu 22.04 LTS, Rocky Linux 9

#### Kubernetes Worker
- **CPU**: 2-4 cores
- **Memory**: 4-16 GB
- **Storage**: 50-200 GB
- **Best Distros**: Ubuntu 24.04.3 LTS, Rocky Linux 9

#### Lightweight Services
- **CPU**: 1-2 cores
- **Memory**: 1-2 GB
- **Storage**: 20-50 GB
- **Best Distros**: Debian 12, Ubuntu 22.04 LTS

## 🔄 Update and Maintenance

### Template Updates
```bash
# Rebuild templates with latest packages
./build-template.sh

# Update infrastructure to use new templates
cd opentofu
tofu apply -replace="module.vm_name.proxmox_vm_qemu.vm"
```

### System Updates
```bash
# Ubuntu/Debian systems
ansible all -i inventory/hosts.yml -m apt -a "upgrade=yes update_cache=yes" --become

# Rocky Linux systems
ansible rocky -i inventory/hosts.yml -m dnf -a "name=* state=latest" --become
```

## 🚨 Emergency Procedures

### Template Build Failures
1. Check internet connectivity
2. Verify ISO URLs are current
3. Enable debug logging: `PACKER_LOG=1`
4. Check Proxmox storage space

### Deployment Failures
1. Verify template exists in Proxmox
2. Check network configuration
3. Validate credentials
4. Review OpenTofu state: `tofu show`

### Ansible Failures
1. Test connectivity: `ansible all -m ping`
2. Check SSH key authentication
3. Verify sudo privileges
4. Review playbook syntax: `ansible-playbook --syntax-check`

## 📈 Next Steps After Deployment

1. **Configure Monitoring**: Set up Prometheus/Grafana
2. **Implement Backups**: Configure automated backup strategies
3. **Security Hardening**: Apply additional security measures
4. **Service Deployment**: Deploy your applications
5. **Documentation**: Document your specific configurations

## 🔗 Additional Resources

- **Distribution Documentation**: Check each OS's official documentation
- **Ansible Galaxy**: Explore additional roles and collections
- **Proxmox Community**: Join forums for troubleshooting help
- **K3s Documentation**: For Kubernetes-specific configurations

---

**💡 Pro Tip**: Start with one stable distribution (Ubuntu 22.04 LTS or Rocky Linux 9) for your first deployment, then expand to other distributions as needed.

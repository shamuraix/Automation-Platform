# Ansible Integration with Packer and OpenTofu

This directory contains Ansible playbooks and configuration for both Packer template building and OpenTofu post-deployment configuration.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Packer      │───▶│    Template     │───▶│    OpenTofu     │
│  + Ansible      │    │   (with tools   │    │   + Ansible     │
│  Provisioning   │    │   pre-installed)│    │  Configuration  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Directory Structure

```
ansible/
├── ansible.cfg                    # Ansible configuration
├── requirements.yml               # Galaxy roles and collections
├── inventory/
│   └── hosts.yml                  # Dynamic inventory for all VMs
├── playbooks/
│   ├── packer-base-setup.yml      # Base system setup for Packer
│   ├── packer-docker.yml          # Docker installation for Packer
│   ├── packer-kubernetes.yml      # Kubernetes tools for Packer
│   ├── k3s-servers.yml            # K3s server configuration
│   ├── k3s-workers.yml            # K3s worker configuration
│   ├── docker-swarm.yml           # Docker Swarm cluster setup
│   └── vault-ha.yml               # Hardened Vault installation and config
├── templates/
│   ├── k3s-server-init.service.j2 # K3s initial server service
│   ├── k3s-server-join.service.j2 # K3s additional server service
│   └── k3s-agent.service.j2       # K3s worker agent service
└── roles/                         # Custom Ansible roles (future expansion)
```

## Two-Stage Provisioning

### Stage 1: Packer Template Building
Ansible is used during Packer builds to install and configure:
- Base system packages and security
- Docker Engine and tools
- Kubernetes components (kubelet, kubectl, helm, etc.)
- System hardening and optimization

### Stage 2: OpenTofu Post-Deployment
After VMs are deployed, Ansible configures:
- K3s cluster formation and joining
- Docker Swarm initialization
- Service-specific configurations
- Application deployment

## Quick Start

### 1. Prerequisites
```bash
# Install Ansible
sudo apt-get update
sudo apt-get install -y ansible

# Verify installation
ansible --version

# Install role and collection dependencies
ansible-galaxy install -r ansible/requirements.yml
```

### 2. Build Packer Template with Ansible
```bash
# Use the build script which includes Ansible template option
./build-template.sh
# Choose option 2 for Ansible-enhanced template
```

### 3. Deploy Infrastructure with OpenTofu + Ansible
```bash
# Initialize OpenTofu (includes Ansible provider)
tofu init

# Plan deployment
tofu plan

# Apply infrastructure (will also run Ansible post-configuration)
tofu apply
```

## Packer Ansible Integration

### Provisioner Configuration
The Packer configuration uses `ansible-local` provisioner:

```hcl
provisioner "ansible-local" {
  playbook_file = "ansible/playbooks/packer-base-setup.yml"
  extra_arguments = [
    "--extra-vars", "ansible_user=${var.ssh_username}",
    "-v"
  ]
}
```

### Benefits
- **Consistent Templates**: Every VM starts with identical configuration
- **Modular Playbooks**: Separate concerns (base, docker, k8s)
- **Version Control**: Ansible playbooks are versioned with infrastructure
- **Reproducible Builds**: Same template every time

## OpenTofu Ansible Integration

### Resource Configuration
OpenTofu uses the Ansible provider for post-deployment:

```hcl
resource "ansible_playbook" "k3s_servers" {
  depends_on = [module.k3s_servers]
  
  playbook   = "ansible/playbooks/k3s-servers.yml"
  name       = "k3s-servers"
  replayable = true

  extra_vars = {
    k3s_cluster_token = "secure-k3s-token-change-me"
  }
}
```

### Benefits
- **Declarative Configuration**: Infrastructure and configuration as code
- **Dependency Management**: Ensure VMs exist before configuration
- **State Management**: Track configuration state with OpenTofu
- **Idempotent Operations**: Safe to re-run configurations

## Playbook Descriptions

### Packer Playbooks

#### `packer-base-setup.yml`
- System updates and essential packages
- Security hardening (UFW, fail2ban)
- Time synchronization and system services
- User configuration and permissions

#### `packer-docker.yml`
- Docker Engine installation
- Docker Compose setup
- User group configuration
- Docker daemon optimization

#### `packer-kubernetes.yml`
- Kubernetes tools (kubelet, kubeadm, kubectl)
- Container runtime configuration
- CNI setup and optimization
- Helm and additional K8s tools

### Deployment Playbooks

#### `k3s-servers.yml`
- K3s binary installation
- Cluster initialization and joining
- Service configuration and startup
- Kubeconfig setup for users

#### `k3s-workers.yml`
- K3s agent installation
- Worker node joining to cluster
- Service configuration
- Node labeling and taints

#### `docker-swarm.yml`
- Swarm cluster initialization
- Manager and worker node joining
- Token management and security
- Service mesh configuration

#### `vault-ha.yml`
- Applies CIS Level 1 hardening for RHEL 9.6 using `ansible-lockdown.RHEL9-CIS`
- Installs HashiCorp Vault with system-level protections using `robertdebock.vault`
- Manages TLS assets and generates `vault.hcl` via `robertdebock.vault_configuration` with Raft storage defaults

## Configuration Management

### Inventory Management
The inventory is automatically managed to match your OpenTofu configuration:

```yaml
[k3s_servers]
hlab-k3s-srv-01 ansible_host=10.0.10.50
hlab-k3s-srv-02 ansible_host=10.0.10.51
hlab-k3s-srv-03 ansible_host=10.0.10.52
```

### Variable Management
- Global variables in `ansible.cfg` and `hosts.yml`
- Playbook-specific variables in each playbook
- Runtime variables passed from OpenTofu

### Security Considerations
- SSH key-based authentication
- Secure token generation for clusters
- Firewall configuration and hardening
- Regular security updates automation

## Customization

### Adding New Services
1. Create a new playbook in `playbooks/`
2. Add corresponding OpenTofu `ansible_playbook` resource
3. Update inventory groups as needed
4. Test in development environment

### Modifying Existing Configuration
1. Update relevant playbook files
2. Test changes with `ansible-playbook --check`
3. Apply with OpenTofu or run playbook directly
4. Verify configuration on target systems

### Creating Custom Roles
```bash
# Create new role structure
cd ansible/roles
ansible-galaxy init my-custom-role

# Edit role tasks, handlers, etc.
# Reference role in playbooks
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failures**
   ```bash
   # Test connectivity
   ansible all -m ping
   
   # Check SSH configuration
   ansible all -m setup --limit failing_host
   ```

2. **Playbook Execution Errors**
   ```bash
   # Run with increased verbosity
   ansible-playbook -vvv playbooks/k3s-servers.yml
   
   # Check specific host
   ansible-playbook --limit specific_host playbooks/k3s-servers.yml
   ```

3. **OpenTofu Ansible Provider Issues**
   ```bash
   # Re-initialize providers
   tofu init -upgrade
   
   # Check provider logs
   TF_LOG=DEBUG tofu apply
   ```

### Best Practices

1. **Use Check Mode**: Test playbooks with `--check` before applying
2. **Limit Scope**: Use `--limit` to target specific hosts during testing
3. **Version Control**: Commit playbook changes before infrastructure changes
4. **Testing**: Use development environment for playbook testing
5. **Documentation**: Document custom variables and configurations

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Validate Ansible Playbooks
  run: |
    ansible-playbook --syntax-check ansible/playbooks/*.yml
    
- name: Build Packer Template
  run: |
    packer validate packer/builds/linux/ubuntu/24.04.3/template.pkr.hcl
    packer build packer/builds/linux/ubuntu/24.04.3/template.pkr.hcl
```

This Ansible integration provides a robust, scalable solution for managing your homelab infrastructure with consistent, repeatable deployments.

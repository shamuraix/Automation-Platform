#!/bin/bash
# Build script for Packer templates with Ansible provisioning

set -e

echo "Building Ubuntu 22.04 template with Packer and Ansible..."

# Check if packer.pkrvars.hcl exists
if [ ! -f "packer/packer.pkrvars.hcl" ]; then
    echo "Error: packer/packer.pkrvars.hcl not found!"
    echo "Please copy packer/packer.pkrvars.hcl.example to packer/packer.pkrvars.hcl and configure it."
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "Warning: ansible-playbook not found. Installing Ansible..."
    sudo apt-get update
    sudo apt-get install -y ansible
fi

# Initialize Packer
echo "Initializing Packer..."
packer init packer/

# Validate Ansible-enhanced Packer configuration
echo "Validating Ansible-enhanced Packer configuration..."
packer validate -var-file="packer/packer.pkrvars.hcl" packer/ubuntu-22.04-ansible.pkr.hcl

# Build the Ansible-enhanced template
echo "Building Ansible-enhanced template..."
packer build -var-file="packer/packer.pkrvars.hcl" packer/ubuntu-22.04-ansible.pkr.hcl

echo "Template build completed!"
echo "You can now use the template in your OpenTofu configuration."
echo ""
echo "Next steps:"
echo "1. Update your opentofu/terraform.tfvars with the new template name"
echo "2. cd opentofu && tofu init to download providers"
echo "3. tofu plan && tofu apply to deploy infrastructure"
echo "4. Ansible will automatically configure your VMs post-deployment"

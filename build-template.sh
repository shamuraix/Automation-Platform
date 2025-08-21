#!/bin/bash
# Build script for Packer templates with Ansible provisioning

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}==== $1 ====${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if packer.pkrvars.hcl exists
    if [ ! -f "packer/packer.pkrvars.hcl" ]; then
        print_error "packer/packer.pkrvars.hcl not found!"
        echo "Please copy packer/packer.pkrvars.hcl.example to packer/packer.pkrvars.hcl and configure it."
        exit 1
    fi

    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_warning "ansible-playbook not found. Installing Ansible..."
        sudo apt-get update
        sudo apt-get install -y ansible
    fi
    
    print_info "✅ All prerequisites satisfied"
}

# Initialize Packer
init_packer() {
    print_header "Initializing Packer"
    packer init packer/
}

# Show available templates
show_templates() {
    echo ""
    echo "=== Available Packer Templates ==="
    echo "1) Ubuntu 22.04 LTS (Stable)"
    echo "2) Ubuntu 24.04.3 LTS (Latest)"
    echo "3) Rocky Linux 9 (Stable)"
    echo "4) Rocky Linux 10 (Latest - may be beta/RC)"
    echo "5) Debian 12 (Stable)"
    echo "6) Debian 13 (Testing - may be unstable)"
    echo "7) Build All Templates"
    echo "8) Exit"
    echo ""
}

# Validate and build template
build_template() {
    local template_file=$1
    local template_name=$2
    
    print_header "Building $template_name"
    
    # Validate template
    print_info "Validating $template_name configuration..."
    if packer validate -var-file="packer/packer.pkrvars.hcl" "$template_file"; then
        print_info "✅ Validation successful"
    else
        print_error "❌ Validation failed for $template_name"
        return 1
    fi
    
    # Build template
    print_info "Building $template_name template..."
    if packer build -var-file="packer/packer.pkrvars.hcl" "$template_file"; then
        print_info "✅ $template_name build completed successfully!"
    else
        print_error "❌ $template_name build failed"
        return 1
    fi
}

# Build all templates
build_all_templates() {
    print_header "Building All Templates"
    
    declare -A templates=(
        ["packer/ubuntu-22.04-ansible.pkr.hcl"]="Ubuntu 22.04 LTS"
        ["packer/ubuntu-24.04.3-ansible.pkr.hcl"]="Ubuntu 24.04.3 LTS"
        ["packer/rocky-9-ansible.pkr.hcl"]="Rocky Linux 9"
        ["packer/rocky-10-ansible.pkr.hcl"]="Rocky Linux 10"
        ["packer/debian-12-ansible.pkr.hcl"]="Debian 12"
        ["packer/debian-13-ansible.pkr.hcl"]="Debian 13"
    )
    
    local success_count=0
    local total_count=${#templates[@]}
    
    for template_file in "${!templates[@]}"; do
        if [ -f "$template_file" ]; then
            if build_template "$template_file" "${templates[$template_file]}"; then
                ((success_count++))
            fi
        else
            print_warning "Template file $template_file not found, skipping..."
        fi
        echo ""
    done
    
    print_header "Build Summary"
    print_info "Successfully built: $success_count/$total_count templates"
    
    if [ $success_count -eq $total_count ]; then
        print_info "🎉 All templates built successfully!"
    else
        print_warning "⚠️  Some templates failed to build"
    fi
}

# Main execution
main() {
    print_header "Packer Template Builder with Ansible Provisioning"
    
    check_prerequisites
    init_packer
    
    while true; do
        show_templates
        read -p "Please select a template to build [1-8]: " choice
        
        case $choice in
            1)
                build_template "packer/ubuntu-22.04-ansible.pkr.hcl" "Ubuntu 22.04 LTS"
                ;;
            2)
                build_template "packer/ubuntu-24.04.3-ansible.pkr.hcl" "Ubuntu 24.04.3 LTS"
                ;;
            3)
                build_template "packer/rocky-9-ansible.pkr.hcl" "Rocky Linux 9"
                ;;
            4)
                build_template "packer/rocky-10-ansible.pkr.hcl" "Rocky Linux 10"
                ;;
            5)
                build_template "packer/debian-12-ansible.pkr.hcl" "Debian 12"
                ;;
            6)
                build_template "packer/debian-13-ansible.pkr.hcl" "Debian 13"
                ;;
            7)
                build_all_templates
                ;;
            8)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-8."
                ;;
        esac
        
        echo ""
        echo "Template build completed!"
        echo ""
        echo "Next steps:"
        echo "1. Update your opentofu/terraform.tfvars with the new template name"
        echo "2. cd opentofu && tofu init to download providers"
        echo "3. tofu plan && tofu apply to deploy infrastructure"
        echo "4. Ansible will automatically configure your VMs post-deployment"
        echo ""
        read -p "Press Enter to continue or Ctrl+C to exit..."
    done
}

# Run main function
main "$@"

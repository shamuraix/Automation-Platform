#!/bin/bash
# Deployment script for the Automation Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}==== $1 ====${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if packer is installed
    if ! command -v packer &> /dev/null; then
        print_error "Packer is not installed. Please install it first."
        exit 1
    fi
    
    # Check if tofu is installed
    if ! command -v tofu &> /dev/null; then
        print_error "OpenTofu is not installed. Please install it first."
        exit 1
    fi
    
    # Check if ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_warning "Ansible is not installed. Installing..."
        sudo apt-get update
        sudo apt-get install -y ansible
    fi
    
    echo "✅ All prerequisites are satisfied"
}

# Function to build templates
build_template() {
    print_header "Building Packer Template"
    
    if [ ! -f "packer/packer.pkrvars.hcl" ]; then
        print_error "packer/packer.pkrvars.hcl not found!"
        echo "Please copy packer/packer.pkrvars.hcl.example to packer/packer.pkrvars.hcl and configure it."
        exit 1
    fi
    
    ./build-template.sh
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Infrastructure with OpenTofu"
    
    cd opentofu
    
    if [ ! -f "terraform.tfvars" ]; then
        print_error "opentofu/terraform.tfvars not found!"
        echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it."
        exit 1
    fi
    
    # Initialize OpenTofu
    echo "Initializing OpenTofu..."
    tofu init
    
    # Plan deployment
    echo "Planning deployment..."
    tofu plan
    
    # Ask for confirmation
    read -p "Do you want to apply these changes? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        tofu apply
    else
        echo "Deployment cancelled."
    fi
    
    cd ..
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_header "Destroying Infrastructure"
    
    cd opentofu
    
    print_warning "This will destroy ALL infrastructure managed by this configuration!"
    read -p "Are you sure you want to continue? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        tofu destroy
    else
        echo "Destruction cancelled."
    fi
    
    cd ..
}

# Function to show status
show_status() {
    print_header "Infrastructure Status"
    
    cd opentofu
    echo "Current OpenTofu state:"
    tofu show
    cd ..
}

# Main menu
show_menu() {
    echo ""
    echo "=== Automation Platform Deployment Script ==="
    echo "1. Check Prerequisites"
    echo "2. Build Packer Template"
    echo "3. Deploy Infrastructure"
    echo "4. Show Status"
    echo "5. Destroy Infrastructure"
    echo "6. Exit"
    echo ""
}

# Main execution
main() {
    while true; do
        show_menu
        read -p "Please select an option [1-6]: " choice
        
        case $choice in
            1)
                check_prerequisites
                ;;
            2)
                check_prerequisites
                build_template
                ;;
            3)
                check_prerequisites
                deploy_infrastructure
                ;;
            4)
                show_status
                ;;
            5)
                destroy_infrastructure
                ;;
            6)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-6."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"

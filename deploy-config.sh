#!/bin/bash
# Deployment script for the Automation Platform
# Configuration-driven deployment using project.json

set -e

# Default configuration file
CONFIG_FILE="project.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if jq is installed for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "Installing jq for JSON parsing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Function to read configuration from JSON
read_config() {
    local key=$1
    jq -r "$key" "$CONFIG_FILE" 2>/dev/null || echo ""
}

# Function to read array from configuration
read_config_array() {
    local key=$1
    jq -r "$key[]" "$CONFIG_FILE" 2>/dev/null || echo ""
}

print_header() {
    echo -e "${GREEN}==== $1 ====${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
}

# Function to check prerequisites using configuration
check_prerequisites() {
    local project_name=$(read_config '.project.name')
    print_header "Checking Prerequisites for $project_name"
    
    # Check each required tool from configuration
    local tools=$(jq -r '.required_tools[] | @base64' "$CONFIG_FILE")
    
    for tool_data in $tools; do
        local tool=$(echo "$tool_data" | base64 --decode)
        local name=$(echo "$tool" | jq -r '.name')
        local command=$(echo "$tool" | jq -r '.command')
        local install_cmd=$(echo "$tool" | jq -r '.install_command')
        local description=$(echo "$tool" | jq -r '.description')
        
        if ! command -v "$command" &> /dev/null; then
            if [[ "$name" == "ansible" ]]; then
                print_warning "$description is not installed. Installing..."
                eval "$install_cmd"
            else
                print_error "$description is not installed. Please install it first."
                echo "Install command: $install_cmd"
                exit 1
            fi
        fi
    done
    
    local success_msg=$(read_config '.messages.prerequisites_satisfied')
    echo "$success_msg"
}

# Function to build templates using configuration
build_template() {
    print_header "Building Packer Template"
    
    local packer_vars=$(read_config '.config_files.packer_vars.path')
    local packer_example=$(read_config '.config_files.packer_vars.example')
    
    if [ ! -f "$packer_vars" ]; then
        print_error "$packer_vars not found!"
        echo "Please copy $packer_example to $packer_vars and configure it."
        exit 1
    fi
    
    ./build-template-config.sh
}

# Function to deploy infrastructure using configuration
deploy_infrastructure() {
    local opentofu_dir=$(read_config '.directories.opentofu')
    print_header "Deploying Infrastructure with OpenTofu"
    
    cd "$opentofu_dir"
    
    local terraform_vars=$(read_config '.config_files.terraform_vars.path' | sed "s|opentofu/||")
    local terraform_example=$(read_config '.config_files.terraform_vars.example' | sed "s|opentofu/||")
    
    if [ ! -f "$terraform_vars" ]; then
        print_error "$terraform_vars not found!"
        echo "Please copy $terraform_example to $terraform_vars and configure it."
        exit 1
    fi
    
    # Get commands from configuration
    local init_cmd=$(read_config '.commands.tofu_init')
    local plan_cmd=$(read_config '.commands.tofu_plan')
    local apply_cmd=$(read_config '.commands.tofu_apply')
    
    # Initialize OpenTofu
    echo "Initializing OpenTofu..."
    eval "$init_cmd"
    
    # Plan deployment
    echo "Planning deployment..."
    eval "$plan_cmd"
    
    # Ask for confirmation using configured prompt
    local confirm_prompt=$(read_config '.prompts.deploy_confirm')
    read -p "$confirm_prompt" confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        eval "$apply_cmd"
    else
        echo "Deployment cancelled."
    fi
    
    cd ..
}

# Function to destroy infrastructure using configuration
destroy_infrastructure() {
    print_header "Destroying Infrastructure"
    
    local opentofu_dir=$(read_config '.directories.opentofu')
    cd "$opentofu_dir"
    
    local warning_msg=$(read_config '.prompts.destroy_warning')
    local confirm_prompt=$(read_config '.prompts.destroy_confirm')
    local destroy_cmd=$(read_config '.commands.tofu_destroy')
    
    print_warning "$warning_msg"
    read -p "$confirm_prompt" confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        eval "$destroy_cmd"
    else
        echo "Destruction cancelled."
    fi
    
    cd ..
}

# Function to show status using configuration
show_status() {
    print_header "Infrastructure Status"
    
    local opentofu_dir=$(read_config '.directories.opentofu')
    local show_cmd=$(read_config '.commands.tofu_show')
    
    cd "$opentofu_dir"
    echo "Current OpenTofu state:"
    eval "$show_cmd"
    cd ..
}

# Function to show menu using configuration
show_menu() {
    echo ""
    local welcome_msg=$(read_config '.messages.welcome')
    echo "=== $welcome_msg ==="
    
    # Read menu options from configuration
    local options=$(jq -r '.menu_options.main[] | "\(.id)) \(.title)"' "$CONFIG_FILE")
    echo "$options"
    echo ""
}

# Main execution using configuration
main() {
    # Check if configuration file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file $CONFIG_FILE not found!"
        exit 1
    fi
    
    local project_name=$(read_config '.project.name')
    local project_desc=$(read_config '.project.description')
    
    while true; do
        show_menu
        local select_prompt=$(read_config '.messages.select_option')
        local option_range=$(jq -r '.menu_options.main | length' "$CONFIG_FILE")
        read -p "$select_prompt [1-$option_range]: " choice
        
        # Get function name for the selected choice
        local function_name=$(jq -r ".menu_options.main[] | select(.id == $choice) | .function" "$CONFIG_FILE" 2>/dev/null)
        
        case $function_name in
            "check_prerequisites")
                check_prerequisites
                ;;
            "build_template")
                check_prerequisites
                build_template
                ;;
            "deploy_infrastructure")
                check_prerequisites
                deploy_infrastructure
                ;;
            "show_status")
                show_status
                ;;
            "destroy_infrastructure")
                destroy_infrastructure
                ;;
            "exit")
                local goodbye_msg=$(read_config '.messages.goodbye')
                echo "$goodbye_msg"
                exit 0
                ;;
            *)
                local invalid_msg=$(read_config '.messages.invalid_option')
                print_error "$invalid_msg"
                ;;
        esac
        
        echo ""
        local continue_msg=$(read_config '.messages.continue')
        read -p "$continue_msg"
    done
}

# Run main function
main "$@"

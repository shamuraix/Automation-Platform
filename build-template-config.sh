#!/bin/bash
# Build script for Packer templates with Ansible provisioning
# Configuration-driven template building using project.json

set -e

# Default configuration file
CONFIG_FILE="project.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check prerequisites using configuration
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local packer_vars="packer/shared/packer.pkrvars.hcl"
    local packer_example="packer/packer.pkrvars.hcl.example"
    
    # Check if packer.pkrvars.hcl exists
    if [ ! -f "$packer_vars" ]; then
        print_error "$packer_vars not found!"
        echo "Please copy $packer_example to $packer_vars and configure it."
        exit 1
    fi

    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_warning "ansible-playbook not found. Installing Ansible..."
        sudo apt-get update
        sudo apt-get install -y ansible
    fi
    
    print_info "Prerequisites satisfied"
}

# Initialize Packer using configuration
init_packer() {
    print_header "Initializing Packer"
    
    # Initialize packer plugins in each template directory
    local initialized=false
    local templates=$(jq -c '.templates[]' "$CONFIG_FILE")
    while IFS= read -r template; do
        local template_file=$(echo "$template" | jq -r '.file')
        local template_dir=$(dirname "$template_file")
        
        if [ "$initialized" = false ]; then
            if (cd "$template_dir" && packer init .); then
                print_info "Packer initialization completed"
                initialized=true
                break
            else
                print_error "Packer initialization failed in $template_dir"
            fi
        fi
    done <<< "$templates"
    
    if [ "$initialized" = false ]; then
        print_error "Failed to initialize Packer in any template directory"
        exit 1
    fi
}

# Show available templates from configuration
show_templates() {
    echo ""
    local welcome_msg=$(read_config '.messages.template_welcome')
    echo "=== Available Packer Templates ==="
    
    # Read template options from configuration
    local templates=$(jq -r '.templates[] | "\(.id)) \(.description)"' "$CONFIG_FILE")
    echo "$templates"
    
    # Add additional menu options
    local menu_options=$(jq -r '.menu_options.templates[] | "\(.id)) \(.title)"' "$CONFIG_FILE")
    echo "$menu_options"
    echo ""
}

# Validate and build template using configuration
build_template() {
    local template_file=$1
    local template_name=$2
    
    print_header "Building $template_name"
    
    # Get the template directory and filename
    local template_dir=$(dirname "$template_file")
    local template_filename=$(basename "$template_file")
    local project_root=$(pwd)
    
    # Validate template
    local validation_msg="Validating $template_name configuration..."
    print_info "$validation_msg"
    
    if (cd "$template_dir" && packer validate -var-file="$project_root/packer/shared/packer.pkrvars.hcl" "$template_filename"); then
        local success_msg="Template validation successful"
        print_info "$success_msg"
    else
        local warning_msg="Template validation completed with warnings"
        print_warning "$warning_msg"
    fi
    
    # Build template
    local build_msg="Building $template_name template..."
    print_info "$build_msg"
    
    if (cd "$template_dir" && packer build -var-file="$project_root/packer/shared/packer.pkrvars.hcl" "$template_filename"); then
        local success_msg="Build completed successfully for $template_name"
        print_info "$success_msg"
    else
        local failed_msg="Build failed for $template_name"
        print_error "$failed_msg"
        return 1
    fi
}

# Build all templates using configuration
build_all_templates() {
    print_header "Building All Templates"
    
    local success_count=0
    local total_count=$(jq -r '.templates | length' "$CONFIG_FILE")
    local project_root=$(pwd)
    
    # Build each template individually
    local templates=$(jq -c '.templates[]' "$CONFIG_FILE")
    while IFS= read -r template; do
        local template_id=$(echo "$template" | jq -r '.id')
        local template_name=$(echo "$template" | jq -r '.name')
        local template_file=$(echo "$template" | jq -r '.file')
        local template_dir=$(dirname "$template_file")
        local template_filename=$(basename "$template_file")
        
        print_info "Validating $template_name..."
        if (cd "$template_dir" && packer validate -var-file="$project_root/packer/shared/packer.pkrvars.hcl" "$template_filename"); then
            print_info "Building $template_name..."
            if (cd "$template_dir" && packer build -var-file="$project_root/packer/shared/packer.pkrvars.hcl" "$template_filename"); then
                print_info "$template_name built successfully"
                ((success_count++))
            else
                print_error "$template_name build failed"
            fi
        else
            print_warning "$template_name validation failed, skipping build"
        fi
    done <<< "$templates"
    
    print_header "Build Summary"
    print_info "Build process completed: $success_count/$total_count templates built successfully"
}

# Get template info by ID
get_template_by_id() {
    local template_id=$1
    jq -r ".templates[] | select(.id == $template_id)" "$CONFIG_FILE" 2>/dev/null
}

# Show post-build instructions from configuration
show_post_build_instructions() {
    echo ""
    echo "Template build completed!"
    echo ""
    echo "Next steps:"
    
    local instructions=$(jq -r '.post_build_instructions[]' "$CONFIG_FILE")
    local counter=1
    while IFS= read -r instruction; do
        echo "$counter. $instruction"
        ((counter++))
    done <<< "$instructions"
    
    echo ""
    local continue_msg=$(read_config '.messages.continue')
    read -p "$continue_msg"
}

# Main execution using configuration
main() {
    # Check if configuration file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file $CONFIG_FILE not found!"
        exit 1
    fi
    
    local welcome_msg=$(read_config '.messages.template_welcome')
    print_header "$welcome_msg"
    
    check_prerequisites
    init_packer
    
    while true; do
        show_templates
        local select_msg=$(read_config '.messages.select_template')
        local max_template_id=$(jq -r '.templates | max_by(.id) | .id' "$CONFIG_FILE")
        local max_menu_id=$(jq -r '.menu_options.templates | max_by(.id) | .id' "$CONFIG_FILE")
        read -p "$select_msg [1-$max_menu_id]: " choice
        
        # Check if it's a template choice or menu choice
        if [[ $choice -ge 1 && $choice -le $max_template_id ]]; then
            # It's a template choice
            local template_info=$(get_template_by_id "$choice")
            if [[ -n "$template_info" ]]; then
                local template_file=$(echo "$template_info" | jq -r '.file')
                local template_name=$(echo "$template_info" | jq -r '.name')
                build_template "$template_file" "$template_name"
                show_post_build_instructions
            else
                local invalid_msg=$(read_config '.messages.invalid_option')
                print_error "$invalid_msg"
            fi
        else
            # Check if it's a menu choice
            local function_name=$(jq -r ".menu_options.templates[] | select(.id == $choice) | .function" "$CONFIG_FILE" 2>/dev/null)
            
            case $function_name in
                "build_all_templates")
                    build_all_templates
                    show_post_build_instructions
                    ;;
                "exit")
                    local goodbye_msg=$(read_config '.messages.goodbye')
                    print_info "$goodbye_msg"
                    exit 0
                    ;;
                *)
                    local invalid_msg=$(read_config '.messages.invalid_option')
                    print_error "$invalid_msg"
                    ;;
            esac
        fi
    done
}

# Run main function
main "$@"

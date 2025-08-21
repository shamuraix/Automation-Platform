#!/bin/bash
# Configuration management script for project.json

set -e

CONFIG_FILE="project.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Installing jq for JSON parsing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

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

# Function to backup configuration
backup_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${CONFIG_FILE}.backup.${timestamp}"
    cp "$CONFIG_FILE" "$backup_file"
    print_info "Configuration backed up to $backup_file"
}

# Function to validate configuration
validate_config() {
    print_header "Validating Configuration"
    
    if ! jq . "$CONFIG_FILE" >/dev/null 2>&1; then
        print_error "Invalid JSON in $CONFIG_FILE"
        return 1
    fi
    
    # Check required sections
    local required_sections=(".project" ".directories" ".required_tools" ".templates" ".menu_options")
    
    for section in "${required_sections[@]}"; do
        if ! jq -e "$section" "$CONFIG_FILE" >/dev/null 2>&1; then
            print_error "Missing required section: $section"
            return 1
        fi
    done
    
    print_info "✅ Configuration is valid"
    return 0
}

# Function to show current configuration
show_config() {
    print_header "Current Configuration"
    
    echo "Project Information:"
    echo "  Name: $(jq -r '.project.name' "$CONFIG_FILE")"
    echo "  Description: $(jq -r '.project.description' "$CONFIG_FILE")"
    echo "  Version: $(jq -r '.project.version' "$CONFIG_FILE")"
    echo ""
    
    echo "Available Templates:"
    jq -r '.templates[] | "  \(.id)) \(.name) (\(.status))"' "$CONFIG_FILE"
    echo ""
    
    echo "Required Tools:"
    jq -r '.required_tools[] | "  - \(.name): \(.description)"' "$CONFIG_FILE"
    echo ""
}

# Function to add a new template
add_template() {
    print_header "Adding New Template"
    
    backup_config
    
    read -p "Template name: " name
    read -p "Template description: " description
    read -p "Template file path: " file
    read -p "OS family (ubuntu/debian/rocky/etc): " os_family
    read -p "Version: " version
    read -p "Status (stable/testing/beta): " status
    
    # Get next available ID
    local next_id=$(jq -r '.templates | max_by(.id) | .id + 1' "$CONFIG_FILE")
    
    # Create new template object
    local new_template=$(jq -n \
        --argjson id "$next_id" \
        --arg name "$name" \
        --arg description "$description" \
        --arg file "$file" \
        --arg status "$status" \
        --arg os_family "$os_family" \
        --arg version "$version" \
        '{
            id: $id,
            name: $name,
            description: $description,
            file: $file,
            status: $status,
            os_family: $os_family,
            version: $version
        }')
    
    # Add template to configuration
    jq --argjson template "$new_template" '.templates += [$template]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    print_info "✅ Template added successfully"
}

# Function to remove a template
remove_template() {
    print_header "Removing Template"
    
    show_templates
    read -p "Enter template ID to remove: " template_id
    
    if ! jq -e ".templates[] | select(.id == $template_id)" "$CONFIG_FILE" >/dev/null 2>&1; then
        print_error "Template with ID $template_id not found"
        return 1
    fi
    
    backup_config
    
    # Remove template
    jq --argjson id "$template_id" 'del(.templates[] | select(.id == $id))' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    print_info "✅ Template removed successfully"
}

# Function to show templates
show_templates() {
    echo "Current Templates:"
    jq -r '.templates[] | "  \(.id)) \(.name) - \(.file)"' "$CONFIG_FILE"
    echo ""
}

# Function to update project information
update_project_info() {
    print_header "Updating Project Information"
    
    local current_name=$(jq -r '.project.name' "$CONFIG_FILE")
    local current_desc=$(jq -r '.project.description' "$CONFIG_FILE")
    local current_version=$(jq -r '.project.version' "$CONFIG_FILE")
    
    echo "Current values:"
    echo "  Name: $current_name"
    echo "  Description: $current_desc"
    echo "  Version: $current_version"
    echo ""
    
    read -p "New name (press Enter to keep current): " new_name
    read -p "New description (press Enter to keep current): " new_desc
    read -p "New version (press Enter to keep current): " new_version
    
    backup_config
    
    # Update values if provided
    if [[ -n "$new_name" ]]; then
        jq --arg name "$new_name" '.project.name = $name' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
    
    if [[ -n "$new_desc" ]]; then
        jq --arg desc "$new_desc" '.project.description = $desc' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
    
    if [[ -n "$new_version" ]]; then
        jq --arg version "$new_version" '.project.version = $version' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
    
    print_info "✅ Project information updated"
}

# Function to show menu
show_menu() {
    echo ""
    echo "=== Configuration Management ==="
    echo "1) Show Current Configuration"
    echo "2) Validate Configuration"
    echo "3) Add Template"
    echo "4) Remove Template"
    echo "5) Update Project Info"
    echo "6) Backup Configuration"
    echo "7) Exit"
    echo ""
}

# Main execution
main() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file $CONFIG_FILE not found!"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Please select an option [1-7]: " choice
        
        case $choice in
            1)
                show_config
                ;;
            2)
                validate_config
                ;;
            3)
                add_template
                ;;
            4)
                remove_template
                ;;
            5)
                update_project_info
                ;;
            6)
                backup_config
                ;;
            7)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-7."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"

# Configuration-Driven Deployment System

## Overview

The Automation Platform now uses a configuration-driven approach with `project.json` as the central configuration file. This eliminates hardcoded values in scripts and makes the system more maintainable and flexible.

## 📁 New File Structure

### Configuration Files
- **`project.json`**: Central configuration file containing all project settings
- **`deploy-config.sh`**: Configuration-driven deployment script
- **`build-template-config.sh`**: Configuration-driven template builder
- **`config-manager.sh`**: Configuration management utility

### Legacy Files (Still Available)
- **`deploy.sh`**: Original deployment script
- **`build-template.sh`**: Original template builder

## 🔧 Configuration File (`project.json`)

The `project.json` file contains all configurable aspects of the deployment system:

### Main Sections

1. **Project Information**
   ```json
   "project": {
     "name": "Automation Platform",
     "description": "Infrastructure automation platform using Packer, OpenTofu, and Ansible",
     "version": "1.0.0"
   }
   ```

2. **Directory Structure**
   ```json
   "directories": {
     "packer": "packer",
     "opentofu": "opentofu", 
     "ansible": "ansible"
   }
   ```

3. **Required Tools**
   ```json
   "required_tools": [
     {
       "name": "packer",
       "command": "packer",
       "install_command": "sudo apt-get install -y packer",
       "description": "HashiCorp Packer for building VM templates"
     }
   ]
   ```

4. **Templates**
   ```json
   "templates": [
     {
       "id": 1,
       "name": "Ubuntu 22.04 LTS",
       "description": "Ubuntu 22.04 LTS (Stable)",
       "file": "packer/ubuntu-22.04-ansible.pkr.hcl",
       "status": "stable",
       "os_family": "ubuntu",
       "version": "22.04"
     }
   ]
   ```

5. **Menu Options & Messages**
   - Configurable menu items and descriptions
   - Customizable messages and prompts
   - Flexible command definitions

## 🚀 Usage

### Using Configuration-Driven Scripts

#### 1. Main Deployment Script
```bash
./deploy-config.sh
```

#### 2. Template Builder
```bash
./build-template-config.sh
```

#### 3. Configuration Manager
```bash
./config-manager.sh
```

### Configuration Management

The `config-manager.sh` script provides utilities to:

1. **View Configuration**: Display current settings
2. **Validate Configuration**: Check JSON syntax and required sections
3. **Add Templates**: Add new Packer templates
4. **Remove Templates**: Remove existing templates
5. **Update Project Info**: Modify project metadata
6. **Backup Configuration**: Create timestamped backups

### Example: Adding a New Template

```bash
./config-manager.sh
# Select option 3 (Add Template)
# Fill in the prompted information:
# - Template name: CentOS Stream 9
# - Description: CentOS Stream 9 (Rolling Release)
# - File path: packer/centos-stream9-ansible.pkr.hcl
# - OS family: centos
# - Version: 9
# - Status: stable
```

## 🔄 Migration Path

### From Legacy to Configuration-Driven

1. **Immediate**: Both systems work side-by-side
   - Legacy scripts: `deploy.sh`, `build-template.sh`
   - New scripts: `deploy-config.sh`, `build-template-config.sh`

2. **Testing**: Use new scripts to verify functionality
   ```bash
   # Test new deployment script
   ./deploy-config.sh
   
   # Test new template builder
   ./build-template-config.sh
   ```

3. **Full Migration**: Replace legacy scripts when ready
   ```bash
   # Backup legacy scripts
   mv deploy.sh deploy-legacy.sh
   mv build-template.sh build-template-legacy.sh
   
   # Use new scripts as primary
   mv deploy-config.sh deploy.sh
   mv build-template-config.sh build-template.sh
   ```

## ✅ Benefits

### 1. **Centralized Configuration**
- All settings in one place (`project.json`)
- No hardcoded values in scripts
- Easy to modify without script changes

### 2. **Maintainability**
- Add/remove templates without script modification
- Update messages and prompts through configuration
- Version control for configuration changes

### 3. **Flexibility**
- Template metadata (status, OS family, version)
- Configurable command templates
- Customizable menu structure

### 4. **Consistency**
- Unified configuration format
- Standardized template definitions
- Consistent command patterns

### 5. **Extensibility**
- Easy to add new template types
- Simple to integrate new tools
- Scalable menu system

## 🔍 Configuration Validation

The system includes built-in validation:

```bash
# Validate configuration file
./config-manager.sh
# Select option 2 (Validate Configuration)
```

### Validation Checks
- JSON syntax validation
- Required section verification
- Template file existence
- Command template validation

## 📋 Example Workflows

### 1. Adding Support for New OS

```bash
# 1. Create the Packer template file
# 2. Add template via configuration manager
./config-manager.sh  # Option 3: Add Template

# 3. Template is immediately available in builders
./build-template-config.sh
```

### 2. Updating Project Information

```bash
# Update project metadata
./config-manager.sh  # Option 5: Update Project Info
```

### 3. Backing Up Configuration

```bash
# Create timestamped backup
./config-manager.sh  # Option 6: Backup Configuration
```

## 🛡️ Safety Features

1. **Automatic Backups**: Configuration changes create timestamped backups
2. **Validation**: JSON and structure validation before use
3. **Graceful Fallbacks**: Error handling for missing configurations
4. **Legacy Support**: Original scripts remain functional

## 🔧 Troubleshooting

### Common Issues

1. **Missing jq**: Scripts automatically install `jq` if missing
2. **Invalid JSON**: Use validation option to check syntax
3. **Missing Templates**: Configuration manager shows file existence
4. **Permission Issues**: Ensure scripts are executable (`chmod +x`)

### Debug Mode

```bash
# Enable verbose output
set -x
./deploy-config.sh
```

This configuration-driven approach provides a robust, maintainable, and scalable foundation for the Automation Platform deployment system.

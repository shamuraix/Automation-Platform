# Packer Configuration Updates

## Summary of Changes

This document outlines the updates made to resolve duplicate variable errors and modernize the Packer configuration.

## ✅ Issues Resolved

### 1. Duplicate Variable Errors
- **Problem**: Multiple Packer template files defined the same variables, causing initialization failures
- **Solution**: Created a shared `packer/variables.pkr.hcl` file containing all common variables and configurations

### 2. Deprecated ISO Configuration
- **Problem**: Using deprecated `iso_url`, `iso_checksum`, and `iso_storage_pool` parameters
- **Solution**: Migrated to the new `boot_iso` block format

### 3. Shutdown Command Compatibility
- **Problem**: `shutdown_command` parameter causing validation errors with current Proxmox plugin
- **Solution**: Removed `shutdown_command` as Packer handles VM shutdown automatically

## 📁 File Structure Changes

### New Shared Configuration File
- **`packer/variables.pkr.hcl`**: Contains shared Packer configuration, plugin requirements, variables, and local values

### Updated Template Files
- **`packer/debian-13-ansible.pkr.hcl`**: Updated to use boot_iso block
- **`packer/rocky-10-ansible.pkr.hcl`**: Updated to use boot_iso block
- **`packer/ubuntu-22.04-ansible.pkr.hcl`**: Updated to use boot_iso block
- **`packer/ubuntu-24.04.3-ansible.pkr.hcl`**: Updated to use boot_iso block

## 🔧 Configuration Changes

### Before (Deprecated)
```hcl
# ISO configuration
iso_url          = "https://example.com/image.iso"
iso_checksum     = "sha256:..."
iso_storage_pool = "local"
```

### After (Modern)
```hcl
# Boot ISO configuration
boot_iso {
  iso_url          = "https://example.com/image.iso"
  iso_checksum     = "sha256:..."
  iso_storage_pool = "local"
}
```

## ✅ Validation Results

- **Before**: Multiple duplicate variable errors preventing initialization
- **After**: Clean validation with no errors or warnings

```bash
$ packer validate -var-file=packer.pkrvars.hcl .
The configuration is valid.
```

## 🚀 Usage

The deployment script now works without any duplicate variable errors:

```bash
./deploy.sh
# Select option 2 (Build Packer Template)
# Choose your desired template (1-6) or build all (7)
```

## 📋 Next Steps

1. **Test builds**: Individual template builds should now work correctly
2. **Update checksums**: Replace placeholder checksums with actual values for Debian 13 and Rocky 10 when available
3. **Monitor for updates**: Keep an eye on Packer plugin updates for any new configuration options

## 🔍 Verification Commands

```bash
# Validate all templates
cd packer && packer validate -var-file=packer.pkrvars.hcl .

# Check syntax only
cd packer && packer validate -syntax-only .

# Run deployment script
./deploy.sh
```

All commands should now execute successfully without duplicate variable errors.

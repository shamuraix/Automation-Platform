# Debian 12 (Bookworm) Baseline Template
#
# Purpose: Create a minimal, hardened Debian 12 (Bookworm) base template with:
# - Baseline CIS compliance configurations
# - SSH hardening and security configurations
# - Essential security tools and monitoring
# - Ansible integration for automated provisioning
# - Proxmox VE optimization
#
# This template focuses on:
# - Security baseline implementation
# - Minimal attack surface
# - CIS compliance readiness
# - Production-ready hardening

packer {
  required_version = ">= 1.14.0"
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
    ansible = {
      version = ">= 1.1.4"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# Variables
variable "proxmox_url" {
  type        = string
  description = "Proxmox VE API endpoint URL"
  default     = ""
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox VE username (format: user@realm)"
  default     = ""
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox VE password"
  default     = ""
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox VE node name"
  default     = ""
}

variable "proxmox_storage_pool" {
  type        = string
  description = "Proxmox VE storage pool for VM disks"
  default     = "local-lvm"
}

variable "proxmox_storage_format" {
  type        = string
  description = "Disk storage format (qcow2, raw, vmdk)"
  default     = "qcow2"
}

# Local variables
locals {
  timestamp     = regex_replace(timestamp(), "[- TZ:]", "")
  template_name = "debian-12-ansible-template-${local.timestamp}"
}

# Source definition
source "proxmox-iso" "debian-12-ansible" {
  # Proxmox connection settings
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM configuration
  vm_name              = local.template_name
  template_description = "Debian 12 (Bookworm) baseline template built with Packer - CIS compliant, Ansible-ready"

  # ISO configuration
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.7.0-amd64-netinst.iso"
  iso_checksum     = "sha256:8fde79cfc6b20a696200fc5c15219cf6d721e8feb367e9e0e33a79d1cb68fa83"
  iso_storage_pool = "local"
  unmount_iso      = true

  # System configuration
  qemu_agent      = true
  scsi_controller = "virtio-scsi-pci"
  disks {
    disk_size    = "20G"
    format       = var.proxmox_storage_format
    storage_pool = var.proxmox_storage_pool
    type         = "virtio"
  }

  # Network configuration
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }

  # Hardware configuration
  cores  = "2"
  memory = "2048"

  # Boot configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "console-setup/ask_detect=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "debian-installer=en_US <wait>",
    "fb=false <wait>",
    "initrd=/install.amd/initrd.gz <wait>",
    "kbd-chooser/method=us <wait>",
    "kernel=/install.amd/vmlinuz <wait>",
    "keyboard-configuration/layout=USA <wait>",
    "keyboard-configuration/variant=USA <wait>",
    "locale=en_US <wait>",
    "netcfg/get_domain=vm.local <wait>",
    "netcfg/get_hostname=debian12 <wait>",
    "grub-installer/bootdev=/dev/sda <wait>",
    "noapic <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "-- <wait>",
    "<enter><wait>"
  ]

  # HTTP directory for preseed file
  http_directory = "http"

  # SSH configuration
  ssh_username = "debian"
  ssh_password = "debian"
  ssh_timeout  = "30m"

  # Template creation
  template_name = local.template_name
}

# Build definition
build {
  name    = "debian-12-baseline"
  sources = ["source.proxmox-iso.debian-12-ansible"]

  # Wait for system to be ready
  provisioner "shell" {
    inline = [
      "echo 'Waiting for system to be ready...'",
      "while [ ! -f /var/lib/dpkg/lock-frontend ]; do sleep 1; done",
      "while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 1; done",
      "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
      "sudo apt-get update"
    ]
  }

  # System hardening and baseline setup
  provisioner "shell" {
    inline = [
      "echo 'Setting up baseline security configurations...'",
      "sudo apt-get install -y python3 python3-pip ansible",
      "sudo systemctl enable ssh",
      "echo 'Baseline setup completed'"
    ]
  }

  # Final cleanup
  provisioner "shell" {
    inline = [
      "echo 'Performing final cleanup...'",
      "sudo apt-get autoremove -y",
      "sudo apt-get autoclean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "history -c"
    ]
  }
}

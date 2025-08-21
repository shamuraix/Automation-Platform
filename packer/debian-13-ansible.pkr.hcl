packer {
  required_version = ">= 1.10.0"
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# Variables for Packer builds
variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox username"
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox password"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve"
}

variable "ssh_username" {
  type        = string
  description = "SSH username for template"
  default     = "debian"
}

variable "ssh_password" {
  type        = string
  description = "SSH password for template"
  default     = "debian"
  sensitive   = true
}

# Local variables
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# Debian 13 (Trixie) Template with Ansible provisioning
source "proxmox-iso" "debian-13-ansible" {
  # Proxmox connection
  proxmox_url              = var.proxmox_endpoint
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM configuration
  vm_name              = "debian-13-ansible-template-${local.timestamp}"
  template_description = "Debian 13 (Trixie) template with Ansible provisioning built on ${timestamp()}"
  
  # ISO configuration - Note: Debian 13 may still be in testing
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso"
  iso_checksum     = "sha256:placeholder_checksum_for_debian_13"
  iso_storage_pool = "local"
  
  # Hardware configuration
  cores    = 2
  memory   = 2048
  sockets  = 1
  cpu_type = "host"
  
  # Disk configuration
  scsi_controller = "virtio-scsi-pci"
  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = "local-lvm"
    format       = "raw"
  }
  
  # Network configuration
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  # Cloud-init configuration
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  
  # Boot configuration for Debian preseed
  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/get_hostname=debian13 <wait>",
    "netcfg/get_domain=local <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "grub-installer/bootdev=/dev/sda <wait>",
    "<enter><wait>"
  ]
  boot_wait = "10s"
  
  # HTTP server for preseed
  http_directory = "packer/http/debian"
  
  # SSH configuration
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"
  
  # Shutdown configuration
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
}

# Build configuration with Ansible
build {
  name = "debian-13-ansible-template"
  sources = ["source.proxmox-iso.debian-13-ansible"]

  # Wait for system to be ready
  provisioner "shell" {
    pause_before = "30s"
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip python3-venv",
      "sudo python3 -m pip install --upgrade pip --break-system-packages"
    ]
  }

  # Install Ansible
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y software-properties-common",
      "sudo apt-get install -y ansible"
    ]
  }

  # Basic system configuration with Ansible
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-base-setup.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=debian",
      "--extra-vars", "os_version=13",
      "-v"
    ]
  }

  # Install Docker with Ansible
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-docker.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=debian",
      "-v"
    ]
  }

  # Install Kubernetes tools with Ansible
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-kubernetes.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=debian",
      "-v"
    ]
  }

  # Final cleanup
  provisioner "shell" {
    inline = [
      # Clear logs
      "sudo find /var/log -type f -exec truncate -s 0 {} \\;",
      # Clear temporary files
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      # Clear bash history
      "history -c",
      "sudo rm -f /root/.bash_history",
      "sudo rm -f /home/${var.ssh_username}/.bash_history",
      # Clear apt cache
      "sudo apt-get clean",
      "sudo apt-get autoremove -y",
      # Final sync
      "sync"
    ]
  }
}

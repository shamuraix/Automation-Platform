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
  default     = "rocky"
}

variable "ssh_password" {
  type        = string
  description = "SSH password for template"
  default     = "rocky"
  sensitive   = true
}

# Local variables
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# Rocky Linux 10 Template with Ansible provisioning
source "proxmox-iso" "rocky-10-ansible" {
  # Proxmox connection
  proxmox_url              = var.proxmox_endpoint
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM configuration
  vm_name              = "rocky-10-ansible-template-${local.timestamp}"
  template_description = "Rocky Linux 10 template with Ansible provisioning built on ${timestamp()}"
  
  # ISO configuration - Note: Rocky 10 may not be released yet, using placeholder
  iso_url          = "https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.0-x86_64-minimal.iso"
  iso_checksum     = "sha256:placeholder_checksum_for_rocky_10"
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
  
  # Boot configuration for Rocky Linux
  boot_command = [
    "<tab><wait>",
    " inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky-ks.cfg",
    "<enter><wait>"
  ]
  boot_wait = "10s"
  
  # HTTP server for kickstart
  http_directory = "packer/http/rocky"
  
  # SSH configuration
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"
  
  # Shutdown configuration
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
}

# Build configuration with Ansible
build {
  name = "rocky-10-ansible-template"
  sources = ["source.proxmox-iso.rocky-10-ansible"]

  # Wait for system to be ready
  provisioner "shell" {
    pause_before = "30s"
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y python3 python3-pip",
      "sudo python3 -m pip install --upgrade pip"
    ]
  }

  # Install Ansible
  provisioner "shell" {
    inline = [
      "sudo dnf install -y epel-release",
      "sudo dnf install -y ansible"
    ]
  }

  # Basic system configuration with Ansible
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-base-setup.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=redhat",
      "--extra-vars", "os_version=10",
      "-v"
    ]
  }

  # Install Docker with Ansible
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-docker.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=redhat",
      "-v"
    ]
  }

  # Install Kubernetes tools with Ansible
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-kubernetes.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=redhat",
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
      # Clear DNF cache
      "sudo dnf clean all",
      # Final sync
      "sync"
    ]
  }
}

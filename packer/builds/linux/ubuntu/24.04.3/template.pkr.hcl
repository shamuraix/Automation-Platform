# Ubuntu 24.04.3 LTS Template with Ansible provisioning

# Packer configuration
packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1.2.3"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.1.4"
    }
  }
}

# Variable declarations
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
  default     = "user"
}

variable "ssh_password" {
  type        = string
  description = "SSH password for template"
  default     = "user"
  sensitive   = true
}

# Local variables
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  # Calculate paths relative to project root
  project_root = "${path.root}/../../../../../"
  http_dir = "${local.project_root}http/ubuntu"
  ansible_playbooks = "${local.project_root}ansible/playbooks"
  # Template naming
  template_name = "ubuntu-24.04.3-ansible-template-${local.timestamp}"
  os_family = "ubuntu"
  os_version = "24.04.3"
}

source "proxmox-iso" "ubuntu-24-04-3-ansible" {
  # Proxmox connection
  proxmox_url              = var.proxmox_endpoint
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM configuration
  vm_name              = local.template_name
  template_description = "Ubuntu ${local.os_version} LTS template with Ansible provisioning built on ${timestamp()}"
  
  # Boot ISO configuration
  boot_iso {
    iso_url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
    iso_checksum     = "sha256:a435f6f393dda581172490eda9f683c32e495158a780b5a1de422ee77d98e909"
    iso_storage_pool = "local"
  }
  
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
  
  # Boot configuration
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot_wait = "5s"
  
  # HTTP server configuration
  http_directory = local.http_dir
  
  # SSH configuration
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"
}

# Build configuration with Ansible
build {
  name = "ubuntu-24-04-3-lts"
  sources = ["source.proxmox-iso.ubuntu-24-04-3-ansible"]

  # Wait for cloud-init to complete
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip python3-venv",
      "sudo python3 -m pip install --upgrade pip --break-system-packages"
    ]
  }

  # Install Ansible on the target for local provisioning
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible"
    ]
  }

  # Basic system configuration with Ansible
  provisioner "ansible-local" {
    playbook_file = "${local.ansible_playbooks}/packer-base-setup.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=${local.os_family}",
      "--extra-vars", "os_version=${local.os_version}",
      "-v"
    ]
  }

  # Install Docker with Ansible
  provisioner "ansible-local" {
    playbook_file = "${local.ansible_playbooks}/packer-docker.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=${local.os_family}",
      "-v"
    ]
  }

  # Install Kubernetes tools with Ansible
  provisioner "ansible-local" {
    playbook_file = "${local.ansible_playbooks}/packer-kubernetes.yml"
    extra_arguments = [
      "--extra-vars", "ansible_user=${var.ssh_username}",
      "--extra-vars", "os_family=ubuntu",
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
      "sudo rm -f /home/ubuntu/.bash_history",
      # Clear cloud-init state
      "sudo cloud-init clean --logs",
      # Final sync
      "sync"
    ]
  }
}

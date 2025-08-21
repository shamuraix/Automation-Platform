resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  description = var.vm_description
  tags        = var.tags
  node_name   = var.node_name

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = var.template_id
    interface    = "virtio0"
    size         = var.disk_size
  }

  network_device {
    bridge = var.network_bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
    user_data_file_id = var.cloud_init_file_id
  }
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_description" {
  description = "Description of the VM"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for the VM"
  type        = list(string)
  default     = []
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "datastore_id" {
  description = "Datastore ID"
  type        = string
  default     = "local-lvm"
}

variable "template_id" {
  description = "Template/ISO file ID (use format 'storage:template-name' for Packer templates)"
  type        = string
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IP address with CIDR"
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = ""
}

variable "cloud_init_file_id" {
  description = "Cloud-init file ID"
  type        = string
  default     = null
}

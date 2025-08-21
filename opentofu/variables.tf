variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
}

variable "proxmox_username" {
  description = "Proxmox VE username"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox VE password"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

# Template variables for Packer-built templates
variable "ubuntu_template_name" {
  description = "Name of the Ubuntu template built by Packer"
  type        = string
  default     = "ubuntu-22.04-template"
}

variable "template_storage" {
  description = "Storage location for templates"
  type        = string
  default     = "local"
}

output "vm_id" {
  description = "VM ID"
  value       = proxmox_virtual_environment_vm.vm.id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "vm_ipv4_address" {
  description = "VM IPv4 address"
  value       = proxmox_virtual_environment_vm.vm.ipv4_addresses
}

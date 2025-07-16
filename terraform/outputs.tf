output "vm_info" {
  description = "Information about created VMs"
  value = {
    for vm in proxmox_vm_qemu.almalinux9_vm : 
    vm.name => {
      id     = vm.id
      vmid   = vm.vmid
      status = try(vm.status, "unknown")
    }
  }
}

output "vm_count" {
  description = "Number of VMs created"
  value       = length(proxmox_vm_qemu.almalinux9_vm)
}

output "access_info" {
  description = "VM access information"
  value = {
    username = var.ci_user
    password = var.ci_password
    note     = "Use 'ssh ${var.ci_user}@<vm-ip>' to connect"
  }
  sensitive = true
}

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API URL"
  default     = "https://pve.tail7a7775.ts.net:8006/api2/json"
}

variable "proxmox_user" {
  type        = string
  description = "Proxmox user for Terraform"
  default     = "terraform@pve!terraform-token"
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox API token for Terraform"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Target Proxmox node"
  default     = "pve"
}

variable "template_name" {
  type        = string
  description = "Name of the template to clone"
  default     = "almalinux9-template"
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
  default     = 2
}

variable "vm_name_prefix" {
  type        = string
  description = "Prefix for VM names"
  default     = "alma9"
}

variable "vm_specs" {
  type = object({
    cores  = number
    memory = number
    disk   = number
  })
  description = "VM specifications"
  default = {
    cores  = 2
    memory = 4096
    disk   = 32
  }
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
  default     = ""
}

variable "ci_user" {
  type        = string
  description = "Cloud-init user"
  default     = "almauser"
}

variable "ci_password" {
  type        = string
  description = "Cloud-init password"
  default     = "AlmaUser123!"
  sensitive   = true
}

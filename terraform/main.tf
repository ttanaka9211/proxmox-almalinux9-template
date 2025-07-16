terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
  pm_parallel     = 2
  pm_timeout      = 600
  pm_log_enable   = true
  pm_log_level    = "info"
  pm_log_file     = "terraform-proxmox.log"
}

# VMリソース定義
resource "proxmox_vm_qemu" "almalinux9_vm" {
  count = var.vm_count
  
  # 基本設定
  name        = format("%s-%02d", var.vm_name_prefix, count.index + 1)
  desc        = "AlmaLinux 9 VM - Managed by Terraform"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true
  
  # VM設定
  agent    = 1
  os_type  = "cloud-init"
  cores    = var.vm_specs.cores
  sockets  = 1
  cpu      = "host"
  memory   = var.vm_specs.memory
  scsihw   = "virtio-scsi-single"
  bootdisk = "scsi0"
  boot     = "order=scsi0"
  
  # ディスク設定
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.vm_specs.disk
          storage = "local-lvm"
        }
      }
    }
  }
  
  # ネットワーク設定
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  # Cloud-Init設定
  ciuser     = var.ci_user
  cipassword = var.ci_password
  
  # DHCP設定
  ipconfig0 = "ip=dhcp"
  
  # SSH公開鍵（設定されている場合）
  sshkeys = var.ssh_public_key != "" ? var.ssh_public_key : null
  
  # 起動設定
  onboot = false
  
  # ライフサイクル設定
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

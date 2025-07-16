variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL"
  default     = "https://pve.tail7a7775.ts.net:8006/api2/json"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox API username with token"
  default     = "packer@pve!packer-token"
}

variable "proxmox_token" {
  type        = string
  description = "Proxmox API token"
  default     = "" # secrets.auto.pkrvars.hcl で設定
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve"
}

variable "template_vm_id" {
  type        = number
  description = "VM ID for the template"
  default     = 9001
}

variable "ssh_password" {
  type        = string
  description = "Temporary SSH password for Packer"
  default     = "PackerTemp123!"
  sensitive   = true
}

variable "iso_url" {
  type        = string
  description = "AlmaLinux 9 ISO URL"
  default     = "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9.6-x86_64-boot.iso"
}

variable "iso_checksum" {
  type        = string
  description = "ISO checksum"
  default     = "sha256:113521ec7f28aa4ab71ba4e5896719da69a0cc46cf341c4ebbd215877214f661"
}

packer {
  required_version = ">= 1.9.0"

  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "almalinux9" {
  # Proxmox接続設定
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true
  
  # VM基本設定
  node                 = var.proxmox_node
  vm_id                = var.template_vm_id
  vm_name              = "almalinux9-template"
  template_description = "AlmaLinux 9.6 Template - Built with Packer on ${formatdate("YYYY-MM-DD hh:mm:ss", timestamp())}"
  
  # ハードウェア設定
  cores    = 2
  sockets  = 1
  memory   = 4096
  cpu_type = "host"
  os       = "l26"
  
  # ISO設定 - Boot ISOを使用
  iso_file         = "local:iso/AlmaLinux-9.6-x86_64-minimal.iso"
  #iso_url          = var.iso_url
  #iso_checksum     = var.iso_checksum
  iso_storage_pool = "local"
  unmount_iso      = true
  
  # UEFIモードを有効化
  bios = "ovmf"
  efi_config {
    efi_storage_pool = "local-lvm"
    efi_type        = "4m"
  }
  
  # ストレージ設定
  disks {
    disk_size    = "20G"
    storage_pool = "local-lvm"
    type         = "scsi"
    discard      = true
    io_thread    = true
  }
  
  # ネットワーク設定
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }
  
  # Cloud-Init設定
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  
  # HTTP server for kickstart

  # ★ boot_waitをさらに長くする
  #boot_wait = "90s"
  
  # ★ boot_commandを調整（GRUBメニューが確実に表示されてから）
    boot_command = [
    "<wait10>",
    "<up><wait>",
    "<tab><wait>",
    " inst.ks=https://raw.githubusercontent.com/ttanaka9211/proxmox-almalinux9-template/main/packer/http/ks.cfg",
    " inst.text console=ttyS0,115200n8",
    "<enter><wait>"
  ]

  # SSH接続設定
  ssh_username           = "root"
  ssh_password           = var.ssh_password
  ssh_timeout            = "30m"
  ssh_pty                = true
  ssh_handshake_attempts = 20
  
  # その他の設定
  qemu_agent      = true
  scsi_controller = "virtio-scsi-single"
}

build {
  name    = "almalinux9"
  sources = ["source.proxmox-iso.almalinux9"]
  
  # ★ VM作成直後、インストール開始前にCPU設定を修正
  provisioner "shell-local" {
    inline = [
      "echo 'Waiting for VM to be created...'",
      "sleep 10",
      "echo 'Setting CPU to host mode...'",
      "ssh root@pve.tail7a7775.ts.net 'qm set ${var.template_vm_id} -cpu host'",
      "echo 'Restarting VM with correct CPU settings...'",
      "ssh root@pve.tail7a7775.ts.net 'qm stop ${var.template_vm_id} --skiplock || true'",
      "sleep 5",
      "ssh root@pve.tail7a7775.ts.net 'qm start ${var.template_vm_id}'",
      "echo 'Waiting for VM to boot...'",
      "sleep 60"
    ]
    only = ["proxmox-iso.almalinux9"]
  }
  
  # システムアップデートと基本パッケージ
  provisioner "shell" {
    inline = [
      "echo 'Starting system configuration...'",
      "dnf update -y",
      "dnf install -y epel-release",
      "dnf install -y qemu-guest-agent cloud-init cloud-utils-growpart gdisk",
      "systemctl enable qemu-guest-agent",
      "systemctl enable cloud-init"
    ]
  }

  # Cloud-Init設定
  provisioner "shell" {
    inline = [
      "echo 'Configuring cloud-init...'",
      "cat > /etc/cloud/cloud.cfg.d/99_pve.cfg << 'EOF'",
      "datasource_list: [ NoCloud, ConfigDrive ]",
      "EOF"
    ]
  }

  # システムのクリーンアップ
  provisioner "shell" {
    inline = [
      "echo 'Cleaning up system...'",
      "dnf clean all",
      "rm -rf /var/cache/dnf",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "rm -rf /tmp/* /var/tmp/*",
      "unset HISTFILE",
      "rm -rf /root/.bash_history",
      "history -c",
      "sync"
    ]
  }
}

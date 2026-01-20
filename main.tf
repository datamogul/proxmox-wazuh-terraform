terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}
provider "proxmox" {
  endpoint  = "https://192.168.178.48:8006"
  api_token="terraform@pam!terramaster=9f0402b5-a74c-4f27-a857-62b52a325187"
  insecure  = true
}
resource "proxmox_virtual_environment_vm" "vm_instance" {
  name      = "vm-instance"
  node_name = "pve"
  clone {
    vm_id = 421  # Template-ID
  }
  agent {
    enabled = true
    timeout = "60s"
  }
  cpu {
    cores = 4
  }
  memory {
    dedicated = 4096
  }
  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }
}
# ============================================================
# DATA SOURCES — busca objetos existentes no vCenter
# ============================================================

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Resolve o datastore de cada VM (usa o padrão se não informado)
locals {
  vm_datastores = {
    for k, vm in var.vms :
    k => vm.datastore != "" ? vm.datastore : var.datastore_default
  }
}

data "vsphere_datastore" "ds" {
  for_each      = var.vms
  name          = local.vm_datastores[each.key]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "portgroup" {
  for_each      = var.vms
  name          = each.value.portgroup
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  for_each      = var.vms
  name          = each.value.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

# ============================================================
# CRIAÇÃO DAS VMs — clone do template Linux
# ============================================================

resource "vsphere_virtual_machine" "vm" {
  for_each = var.vms

  name             = upper(each.value.vm_name)
  resource_pool_id = data.vsphere_resource_pool.pool[each.key].id
  datastore_id     = data.vsphere_datastore.ds[each.key].id
  folder           = each.value.folder != "" ? each.value.folder : null
  annotation       = "${each.value.annotation} | IP: ${each.value.ip_address}"

  num_cpus  = each.value.cpus
  memory    = each.value.memory_mb
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  firmware  = data.vsphere_virtual_machine.template.firmware != "" ? data.vsphere_virtual_machine.template.firmware : "efi"

  network_interface {
    network_id   = data.vsphere_network.portgroup[each.key].id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = each.value.disk_size_gb
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks[0].eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = lower(each.value.vm_name)
        domain    = var.default_dns_suffix
      }

      network_interface {
        ipv4_address = each.value.ip_address
        ipv4_netmask = each.value.netmask
      }

      ipv4_gateway    = each.value.gateway
      dns_server_list = each.value.dns_servers
      dns_suffix_list = [var.default_dns_suffix]
    }
  }

  lifecycle {
    ignore_changes = [
      disk[0].eagerly_scrub,
      firmware,
    ]
  }
}

# O caller configura o provider (credenciais e allow_unverified_ssl).
# Este módulo só resolve o inventário e clona as VMs.

data "vsphere_datacenter" "datacenter" {
  name = var.datacenter
}

# O cluster deixa de ser um data source órfão: o resource pool raiz dele
# é o destino quando a VM não informa resource_pool.
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  for_each      = local.nomes_datastore
  name          = each.value
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  for_each      = local.nomes_portgroup
  name          = each.value
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  for_each      = local.pools_explicitos
  name          = each.value
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm" {
  for_each = var.vms

  name = upper(each.value.vm_name)
  resource_pool_id = (
    contains(keys(local.pools_explicitos), each.key)
    ? data.vsphere_resource_pool.pool[each.key].id
    : data.vsphere_compute_cluster.cluster.resource_pool_id
  )
  datastore_id = data.vsphere_datastore.datastore[local.datastore_por_vm[each.key]].id
  folder       = trimspace(each.value.folder) != "" ? each.value.folder : null
  annotation   = "${trimspace(each.value.annotation) != "" ? each.value.annotation : "Criado via Terraform"} | IP: ${each.value.ip_address}"

  num_cpus  = each.value.cpus
  memory    = each.value.memory_mb
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  firmware  = data.vsphere_virtual_machine.template.firmware != "" ? data.vsphere_virtual_machine.template.firmware : "efi"

  dynamic "network_interface" {
    for_each = local.nics_por_vm[each.key]
    content {
      network_id   = data.vsphere_network.network[network_interface.value.portgroup].id
      adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    }
  }

  dynamic "disk" {
    for_each = local.discos_por_vm[each.key]
    content {
      label       = disk.value.label
      size        = disk.value.size_gb
      unit_number = disk.value.unit_number
      thin_provisioned = (
        disk.value.herdar_provisionamento
        ? data.vsphere_virtual_machine.template.disks[0].thin_provisioned
        : disk.value.thin_provisioned
      )
      eagerly_scrub = (
        disk.value.herdar_provisionamento
        ? data.vsphere_virtual_machine.template.disks[0].eagerly_scrub
        : disk.value.eagerly_scrub
      )
      datastore_id = data.vsphere_datastore.datastore[disk.value.datastore].id
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      dynamic "linux_options" {
        for_each = var.os_type == "linux" ? [1] : []
        content {
          host_name = lower(each.value.vm_name)
          domain    = each.value.domain != null && trimspace(each.value.domain) != "" ? each.value.domain : var.default_dns_suffix
          time_zone = each.value.linux_time_zone != null ? each.value.linux_time_zone : var.linux_time_zone
        }
      }

      dynamic "windows_options" {
        for_each = var.os_type == "windows" ? [1] : []
        content {
          computer_name         = upper(each.value.vm_name)
          admin_password        = var.windows_admin_passwords[each.key]
          full_name             = each.value.full_name
          organization_name     = each.value.organization_name
          product_key           = try(var.windows_product_keys[each.key], null)
          time_zone             = each.value.windows_time_zone != null ? each.value.windows_time_zone : var.windows_time_zone
          auto_logon            = false
          workgroup             = var.domain_name == null ? each.value.workgroup : null
          join_domain           = var.domain_name
          domain_admin_user     = var.domain_name == null ? null : var.domain_admin_user
          domain_admin_password = var.domain_name == null ? null : var.domain_admin_password
          domain_ou             = var.domain_name == null ? null : var.domain_ou
        }
      }

      dynamic "network_interface" {
        for_each = local.nics_por_vm[each.key]
        content {
          ipv4_address = network_interface.value.dhcp ? null : network_interface.value.ip_address
          ipv4_netmask = network_interface.value.dhcp ? null : network_interface.value.netmask
          # No Windows o sufixo de busca é por interface. No Linux o provider
          # ignora dns_domain da NIC e usa dns_suffix_list global.
          dns_domain = (
            var.os_type == "windows" && local.dns_suffix_efetivo[each.key] != null
            ? local.dns_suffix_efetivo[each.key][0]
            : null
          )
        }
      }

      ipv4_gateway    = each.value.gateway
      dns_server_list = each.value.dns_servers
      dns_suffix_list = local.dns_suffix_efetivo[each.key]
    }
  }

  lifecycle {
    # template_uuid muda quando o template é recriado (Packer, conversão).
    # Sem este ignore o provider marca a VM inteira para substituição.
    # eagerly_scrub e firmware seguem o comportamento anterior: o template
    # reporta valores que oscilam sem que o disco ou o firmware real mudem.
    ignore_changes = [
      clone[0].template_uuid,
      disk[0].eagerly_scrub,
      firmware,
    ]

    precondition {
      condition     = length(data.vsphere_virtual_machine.template.disks) > 0
      error_message = "O template ${var.template_name} precisa ter ao menos um disco."
    }

    precondition {
      condition     = length(data.vsphere_virtual_machine.template.network_interface_types) > 0
      error_message = "O template ${var.template_name} precisa ter ao menos uma interface de rede."
    }

    precondition {
      condition     = each.value.disk_size_gb >= data.vsphere_virtual_machine.template.disks[0].size
      error_message = "VM ${each.key}: disk_size_gb (${each.value.disk_size_gb}) é menor que o disco do template ${var.template_name} (${data.vsphere_virtual_machine.template.disks[0].size} GB). O vSphere não reduz disco no clone."
    }
  }
}

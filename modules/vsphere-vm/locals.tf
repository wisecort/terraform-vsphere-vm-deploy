locals {
  # Linux sempre teve sufixo DNS. Windows só envia quando o caller define
  # dns_suffix_list (no módulo ou na VM). Assim uma migração de estado
  # antigo não muda o bloco clone e o provider não propõe recriar a VM.
  dns_suffix_efetivo = {
    for chave, vm in var.vms : chave => (
      vm.dns_suffix_list != null ? vm.dns_suffix_list : (
        var.dns_suffix_list != null ? var.dns_suffix_list : (
          var.os_type == "linux" ? [var.default_dns_suffix] : null
        )
      )
    )
  }

  datastore_por_vm = {
    for chave, vm in var.vms : chave => (
      trimspace(vm.datastore) != "" ? vm.datastore : var.datastore_default
    )
  }

  nomes_datastore = toset(concat(
    values(local.datastore_por_vm),
    flatten([
      for vm in values(var.vms) : [
        for disco in vm.extra_disks : disco.datastore
        if disco.datastore != null && trimspace(disco.datastore) != ""
      ]
    ])
  ))

  nomes_portgroup = toset(flatten([
    for vm in values(var.vms) : concat(
      [vm.portgroup],
      [for nic in vm.extra_nics : nic.portgroup]
    )
  ]))

  pools_explicitos = {
    for chave, vm in var.vms : chave => vm.resource_pool
    if trimspace(vm.resource_pool) != ""
  }

  # unit_number automático: 1..6 e depois 8..15. A unidade 7 fica com o
  # controlador SCSI. A mesma fórmula está na validation de var.vms.
  discos_por_vm = {
    for chave, vm in var.vms : chave => concat(
      [
        {
          label                  = "disk0"
          size_gb                = vm.disk_size_gb
          unit_number            = 0
          herdar_provisionamento = true
          thin_provisioned       = true
          eagerly_scrub          = false
          datastore              = local.datastore_por_vm[chave]
        }
      ],
      [
        for indice, disco in vm.extra_disks : {
          label                  = coalesce(disco.label, format("disk%d", indice + 1))
          size_gb                = disco.size_gb
          unit_number            = disco.unit_number != null ? disco.unit_number : (indice + 1 >= 7 ? indice + 2 : indice + 1)
          herdar_provisionamento = false
          thin_provisioned       = coalesce(disco.thin_provisioned, true)
          eagerly_scrub          = coalesce(disco.eagerly_scrub, false)
          datastore              = disco.datastore != null && trimspace(disco.datastore) != "" ? disco.datastore : local.datastore_por_vm[chave]
        }
      ]
    )
  }

  nics_por_vm = {
    for chave, vm in var.vms : chave => concat(
      [
        {
          portgroup  = vm.portgroup
          ip_address = vm.ip_address
          netmask    = vm.netmask
          dhcp       = false
        }
      ],
      [
        for nic in vm.extra_nics : {
          portgroup  = nic.portgroup
          ip_address = nic.ip_address != null ? nic.ip_address : ""
          netmask    = nic.netmask != null ? nic.netmask : 0
          dhcp       = nic.ip_address == null
        }
      ]
    )
  }
}

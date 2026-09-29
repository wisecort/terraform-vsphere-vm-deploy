output "vms_criadas" {
  description = "VMs gerenciadas: nome no vCenter, IP estático configurado, IP informado pelo guest, UUID e ID."
  value = {
    for chave, vm in vsphere_virtual_machine.vm : chave => {
      nome           = vm.name
      ip_configurado = var.vms[chave].ip_address
      ip             = vm.default_ip_address
      uuid           = vm.uuid
      id             = vm.id
    }
  }
}

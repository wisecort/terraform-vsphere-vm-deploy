output "vms_criadas" {
  description = "Resumo das VMs Windows criadas: nome, IP e UUID no vCenter"
  value = {
    for k, vm in vsphere_virtual_machine.vm :
    k => {
      nome = vm.name
      ip   = vm.default_ip_address
      uuid = vm.uuid
      id   = vm.id
    }
  }
}

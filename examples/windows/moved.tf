# Migração do antigo root windows/, em que a VM era um recurso solto.
# Sem estado anterior, o Terraform ignora este bloco.
moved {
  from = vsphere_virtual_machine.vm
  to   = module.vsphere_vm.vsphere_virtual_machine.vm
}

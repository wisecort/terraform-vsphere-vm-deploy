output "vms_criadas" {
  description = "Resumo das VMs Windows: nome, IPs, UUID e ID."
  value       = module.vsphere_vm.vms_criadas
}

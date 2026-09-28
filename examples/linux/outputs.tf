output "vms_criadas" {
  description = "Resumo das VMs Linux: nome, IPs, UUID e ID."
  value       = module.vsphere_vm.vms_criadas
}

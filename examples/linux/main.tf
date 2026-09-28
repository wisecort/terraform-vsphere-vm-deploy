module "vsphere_vm" {
  source = "../../modules/vsphere-vm"

  os_type            = "linux"
  datacenter         = var.datacenter
  cluster            = var.cluster
  template_name      = var.template_name
  datastore_default  = var.datastore_default
  default_dns_suffix = var.default_dns_suffix
  dns_suffix_list    = var.dns_suffix_list
  linux_time_zone    = var.linux_time_zone
  vms                = var.vms
}

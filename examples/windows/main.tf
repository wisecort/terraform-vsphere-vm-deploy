module "vsphere_vm" {
  source = "../../modules/vsphere-vm"

  os_type                 = "windows"
  datacenter              = var.datacenter
  cluster                 = var.cluster
  template_name           = var.template_name
  datastore_default       = var.datastore_default
  default_dns_suffix      = var.default_dns_suffix
  dns_suffix_list         = var.dns_suffix_list
  windows_time_zone       = var.windows_time_zone
  windows_admin_passwords = var.windows_admin_passwords
  windows_product_keys    = var.windows_product_keys
  domain_name             = var.domain_name
  domain_admin_user       = var.domain_admin_user
  domain_admin_password   = var.domain_admin_password
  domain_ou               = var.domain_ou
  vms                     = var.vms
}

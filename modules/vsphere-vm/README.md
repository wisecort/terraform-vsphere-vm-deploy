# Módulo `vsphere-vm`

Clona uma ou mais VMs no vCenter 8 a partir de um template Linux ou Windows.

O provider (credenciais e `allow_unverified_ssl`) fica no root que chama o módulo. Este diretório não abre sessão no vCenter sozinho.

```hcl
module "vsphere_vm" {
  source = "git::https://github.com/wisecort/terraform-vsphere-vm-deploy.git//modules/vsphere-vm?ref=v1.0.0"

  os_type           = "linux"
  datacenter        = "NOME_DO_DATACENTER"
  cluster           = "NOME_DO_CLUSTER"
  template_name     = "NOME_DO_TEMPLATE_LINUX"
  datastore_default = "NOME_DO_DATASTORE"

  vms = {
    "vm1" = {
      vm_name       = "NOME-DA-VM-01"
      cpus          = 2
      memory_mb     = 4096
      disk_size_gb  = 40
      portgroup     = "NOME_DO_PORTGROUP"
      ip_address    = "192.168.1.101"
      netmask       = 24
      gateway       = "192.168.1.1"
      dns_servers   = ["8.8.8.8"]
      resource_pool = ""
    }
  }
}
```

A tag `v1.0.0` passa a existir quando for publicada em `main`. Os exemplos em [`examples/`](../../examples) usam caminho local.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_vsphere"></a> [vsphere](#requirement\_vsphere) | ~> 2.17 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_vsphere"></a> [vsphere](#provider\_vsphere) | ~> 2.17 |

## Resources

| Name | Type |
| ---- | ---- |
| [vsphere_virtual_machine.vm](https://registry.terraform.io/providers/vmware/vsphere/latest/docs/resources/virtual_machine) | resource |
| [vsphere_compute_cluster.cluster](https://registry.terraform.io/providers/vmware/vsphere/latest/docs/data-sources/compute_cluster) | data source |
| [vsphere_datacenter.datacenter](https://registry.terraform.io/providers/vmware/vsphere/latest/docs/data-sources/datacenter) | data source |
| [vsphere_datastore.datastore](https://registry.terraform.io/providers/vmware/vsphere/latest/docs/data-sources/datastore) | data source |
| [vsphere_network.network](https://registry.terraform.io/providers/vmware/vsphere/latest/docs/data-sources/network) | data source |
| [vsphere_resource_pool.pool](https://registry.terraform.io/providers/vmware/vsphere/latest/docs/data-sources/resource_pool) | data source |
| [vsphere_virtual_machine.template](https://registry.terraform.io/providers/vmware/vsphere/latest/docs/data-sources/virtual_machine) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Nome do cluster. O resource pool raiz deste cluster recebe as VMs que não definem resource\_pool. | `string` | n/a | yes |
| <a name="input_datacenter"></a> [datacenter](#input\_datacenter) | Nome do datacenter no vCenter. | `string` | n/a | yes |
| <a name="input_datastore_default"></a> [datastore\_default](#input\_datastore\_default) | Datastore usado quando a VM ou o disco extra não informa outro. | `string` | n/a | yes |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | Sistema do template e da customização de guest. Aceita linux ou windows. | `string` | n/a | yes |
| <a name="input_template_name"></a> [template\_name](#input\_template\_name) | Nome exato do template a clonar. Um módulo atende um sistema: o template precisa ser do mesmo os\_type. | `string` | n/a | yes |
| <a name="input_vms"></a> [vms](#input\_vms) | Mapa de VMs clonadas do mesmo template. A chave entra no endereço do estado (não use dados sensíveis nela). Campos de Windows fora de os\_type = windows são ignorados, e o inverso também. | ```map(object({ vm_name = string annotation = optional(string, "Criado via Terraform") folder = optional(string, "") cpus = number memory_mb = number datastore = optional(string, "") disk_size_gb = number portgroup = string ip_address = string netmask = number gateway = string dns_servers = list(string) dns_suffix_list = optional(list(string)) resource_pool = optional(string, "") domain = optional(string) linux_time_zone = optional(string) full_name = optional(string, "Administrador") organization_name = optional(string, "Empresa") workgroup = optional(string, "WORKGROUP") windows_time_zone = optional(number) extra_disks = optional(list(object({ size_gb = number label = optional(string) unit_number = optional(number) thin_provisioned = optional(bool) eagerly_scrub = optional(bool) datastore = optional(string) })), []) extra_nics = optional(list(object({ portgroup = string ip_address = optional(string) netmask = optional(number) })), []) }))``` | n/a | yes |
| <a name="input_default_dns_suffix"></a> [default\_dns\_suffix](#input\_default\_dns\_suffix) | Domínio da customização Linux (FQDN) e sufixo DNS padrão do Linux quando dns\_suffix\_list é null. Exemplo: empresa.local. | `string` | `"localdomain"` | no |
| <a name="input_dns_suffix_list"></a> [dns\_suffix\_list](#input\_dns\_suffix\_list) | Sufixos de busca DNS aplicados a todas as VMs. Null usa [default\_dns\_suffix] no Linux e omite o sufixo no Windows (compatível com estado antigo). Defina a lista para enviar dns\_suffix\_list também no Windows. | `list(string)` | `null` | no |
| <a name="input_domain_admin_password"></a> [domain\_admin\_password](#input\_domain\_admin\_password) | Senha da conta de ingresso no domínio. Sensitive. Prefira TF\_VAR\_domain\_admin\_password. | `string` | `null` | no |
| <a name="input_domain_admin_user"></a> [domain\_admin\_user](#input\_domain\_admin\_user) | Conta com permissão de ingresso no Active Directory (usuario@dominio ou DOMINIO\usuario). Obrigatória quando domain\_name está definido. | `string` | `null` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domínio Active Directory para ingresso das VMs Windows. Null mantém o workgroup de cada VM. Uma implantação entra em um único domínio. | `string` | `null` | no |
| <a name="input_domain_ou"></a> [domain\_ou](#input\_domain\_ou) | OU de destino do computador no AD (ex.: OU=Servidores,DC=empresa,DC=local). Exige vSphere 8.0 Update 2 ou superior e não aceita espaços no caminho. | `string` | `null` | no |
| <a name="input_linux_time_zone"></a> [linux\_time\_zone](#input\_linux\_time\_zone) | Fuso horário Linux (banco tz, por exemplo America/Sao\_Paulo). Null mantém o padrão do provider (UTC) e não altera VM já clonada. | `string` | `null` | no |
| <a name="input_windows_admin_passwords"></a> [windows\_admin\_passwords](#input\_windows\_admin\_passwords) | Senhas do administrador local Windows, indexadas pela mesma chave de vms. Obrigatório para cada VM quando os\_type = windows. Variável sensitive: prefira TF\_VAR\_windows\_admin\_passwords e não grave em tfvars versionado. | `map(string)` | `{}` | no |
| <a name="input_windows_product_keys"></a> [windows\_product\_keys](#input\_windows\_product\_keys) | Product keys Windows, indexadas pela chave de vms. Omita a chave da VM para usar a licença do template. Variável sensitive. | `map(string)` | `{}` | no |
| <a name="input_windows_time_zone"></a> [windows\_time\_zone](#input\_windows\_time\_zone) | Código numérico de fuso do Sysprep quando a VM não define windows\_time\_zone. Padrão 65 (SA Western Standard Time: Salvador/Manaus, GMT-3). 235 = Brasília, 85 = GMT, 255 = UTC. | `number` | `65` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vms_criadas"></a> [vms\_criadas](#output\_vms\_criadas) | VMs gerenciadas: nome no vCenter, IP estático configurado, IP informado pelo guest, UUID e ID. |
<!-- END_TF_DOCS -->

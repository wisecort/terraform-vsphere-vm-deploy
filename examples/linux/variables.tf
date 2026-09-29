# Tipo de vms espelha modules/vsphere-vm/variables.tf. Mantenha os dois alinhados.

variable "vsphere_server" {
  description = "Endereço do vCenter. Null usa a variável de ambiente VSPHERE_SERVER."
  type        = string
  default     = null
}

variable "vsphere_user" {
  description = "Usuário do vCenter. Null usa VSPHERE_USER."
  type        = string
  default     = null
}

variable "vsphere_password" {
  description = "Senha do vCenter. Null usa VSPHERE_PASSWORD. Não grave em tfvars versionado."
  type        = string
  default     = null
  sensitive   = true
}

variable "allow_unverified_ssl" {
  description = "Aceita certificado TLS do vCenter que não passa na validação. Mantenha false fora de laboratório."
  type        = bool
  default     = false
}

variable "datacenter" {
  description = "Nome do datacenter no vCenter."
  type        = string
}

variable "cluster" {
  description = "Nome do cluster. VMs sem resource_pool caem no pool raiz deste cluster."
  type        = string
}

variable "template_name" {
  description = "Nome exato do template Linux."
  type        = string
}

variable "datastore_default" {
  description = "Datastore padrão das VMs."
  type        = string
}

variable "default_dns_suffix" {
  description = "Domínio DNS da customização Linux."
  type        = string
  default     = "localdomain"
}

variable "dns_suffix_list" {
  description = "Sufixos de busca DNS. Null usa [default_dns_suffix]."
  type        = list(string)
  default     = null
}

variable "linux_time_zone" {
  description = "Fuso horário Linux (ex.: America/Sao_Paulo). Null deixa o padrão UTC do provider."
  type        = string
  default     = null
}

variable "vms" {
  description = "Mapa de VMs Linux. Veja a referência do módulo para cada campo."
  type = map(object({
    vm_name    = string
    annotation = optional(string, "Criado via Terraform")
    folder     = optional(string, "")

    cpus      = number
    memory_mb = number

    datastore    = optional(string, "")
    disk_size_gb = number

    portgroup       = string
    ip_address      = string
    netmask         = number
    gateway         = string
    dns_servers     = list(string)
    dns_suffix_list = optional(list(string))

    resource_pool = optional(string, "")

    domain          = optional(string)
    linux_time_zone = optional(string)

    full_name         = optional(string, "Administrador")
    organization_name = optional(string, "Empresa")
    workgroup         = optional(string, "WORKGROUP")
    windows_time_zone = optional(number)

    extra_disks = optional(list(object({
      size_gb          = number
      label            = optional(string)
      unit_number      = optional(number)
      thin_provisioned = optional(bool)
      eagerly_scrub    = optional(bool)
      datastore        = optional(string)
    })), [])

    extra_nics = optional(list(object({
      portgroup  = string
      ip_address = optional(string)
      netmask    = optional(number)
    })), [])
  }))
}

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
  description = "Nome exato do template Windows."
  type        = string
}

variable "datastore_default" {
  description = "Datastore padrão das VMs."
  type        = string
}

variable "default_dns_suffix" {
  description = "Sufixo DNS de referência. No Windows o sufixo só é enviado se dns_suffix_list estiver definido."
  type        = string
  default     = "localdomain"
}

variable "dns_suffix_list" {
  description = "Sufixos de busca DNS enviados na customização Windows (dns_suffix_list e dns_domain da NIC)."
  type        = list(string)
  default     = null
}

variable "windows_time_zone" {
  description = "Código de fuso do Sysprep quando a VM não define windows_time_zone. Padrão 65 (Salvador/Manaus)."
  type        = number
  default     = 65
}

variable "windows_admin_passwords" {
  description = "Senhas do administrador local, pela chave da VM. Sensitive. Use TF_VAR_windows_admin_passwords."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "windows_product_keys" {
  description = "Product keys pela chave da VM. Sensitive. Omita para usar a licença do template."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "domain_name" {
  description = "Domínio Active Directory. Null mantém o workgroup de cada VM."
  type        = string
  default     = null
}

variable "domain_admin_user" {
  description = "Conta usada no ingresso ao Active Directory."
  type        = string
  default     = null
}

variable "domain_admin_password" {
  description = "Senha da conta de ingresso. Sensitive. Use TF_VAR_domain_admin_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "domain_ou" {
  description = "OU de destino no AD. Exige vSphere 8.0 Update 2 e caminho sem espaços."
  type        = string
  default     = null
}

variable "vms" {
  description = "Mapa de VMs Windows. admin_password e product_key não ficam mais aqui."
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

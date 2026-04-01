# ============================================================
# CREDENCIAIS vCenter
# ============================================================

variable "vsphere_server" {
  description = "URL ou IP do vCenter Server (ex: vcenter.empresa.local)"
  type        = string
}

variable "vsphere_user" {
  description = "Usuário do vCenter (ex: administrator@vsphere.local)"
  type        = string
}

variable "vsphere_password" {
  description = "Senha do vCenter"
  type        = string
  sensitive   = true
}

# ============================================================
# INFRAESTRUTURA vSphere
# ============================================================

variable "datacenter" {
  description = "Nome do Datacenter no vCenter"
  type        = string
}

variable "cluster" {
  description = "Nome completo do Cluster no vCenter"
  type        = string
}

variable "template_name" {
  description = "Nome exato da VM Template Windows a ser clonada"
  type        = string
}

variable "datastore_default" {
  description = "Datastore padrão usado pelas VMs (pode ser sobrescrito por VM)"
  type        = string
}

# ============================================================
# VMs A CRIAR
# ============================================================

variable "vms" {
  description = "Mapa de VMs Windows a serem criadas via clone do template"

  type = map(object({
    # Identidade
    # ATENÇÃO: vm_name é usado como computer_name — máximo 15 caracteres (limite NetBIOS)
    vm_name    = string
    annotation = optional(string, "Criado via Terraform")
    folder     = optional(string, "")

    # Compute
    cpus      = number
    memory_mb = number

    # Storage
    datastore    = optional(string, "")
    disk_size_gb = number

    # Rede
    portgroup   = string
    ip_address  = string
    netmask     = number        # Prefixo CIDR (ex: 24 para /24)
    gateway     = string
    dns_servers = list(string)

    # Resource Pool
    # Formato: "<NomeCluster>/Resources" para o pool raiz
    # ou      "<NomeCluster>/Resources/<NomePool>" para sub-pools
    resource_pool = string

    # Windows — customização de SO (Sysprep)
    admin_password    = string                              # Senha do administrador local
    full_name         = optional(string, "Administrador")   # Nome do proprietário (Registration Info)
    organization_name = optional(string, "Empresa")         # Nome da organização (Registration Info)
    product_key       = optional(string, "")                # Chave de licença Windows (deixe "" para usar a do template)
    workgroup         = optional(string, "WORKGROUP")
    time_zone         = optional(number, 65)                # 65 = SA Western Standard Time (Salvador/Manaus GMT-3 sem horário de verão)
  }))
}

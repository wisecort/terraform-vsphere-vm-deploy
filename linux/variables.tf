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
  default     = "Datacenter"
}

variable "cluster" {
  description = "Nome completo do Cluster no vCenter"
  type        = string
  default     = "Cluster"
}

variable "template_name" {
  description = "Nome exato da VM Template Linux a ser clonada"
  type        = string
}

variable "datastore_default" {
  description = "Datastore padrão usado pelas VMs (pode ser sobrescrito por VM)"
  type        = string
  default     = "Datastore"
}

variable "default_dns_suffix" {
  description = "Domínio DNS padrão para customização do SO (ex: empresa.local)"
  type        = string
  default     = "localdomain"
}

# ============================================================
# VMs A CRIAR
# ============================================================

variable "vms" {
  description = "Mapa de VMs Linux a serem criadas via clone do template"

  type = map(object({
    # Identidade
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
  }))
}

variable "os_type" {
  description = "Sistema do template e da customização de guest. Aceita linux ou windows."
  type        = string

  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "os_type deve ser \"linux\" ou \"windows\"."
  }
}

variable "datacenter" {
  description = "Nome do datacenter no vCenter."
  type        = string

  validation {
    condition     = length(trimspace(var.datacenter)) > 0
    error_message = "datacenter não pode ser vazio."
  }
}

variable "cluster" {
  description = "Nome do cluster. O resource pool raiz deste cluster recebe as VMs que não definem resource_pool."
  type        = string

  validation {
    condition     = length(trimspace(var.cluster)) > 0
    error_message = "cluster não pode ser vazio."
  }
}

variable "template_name" {
  description = "Nome exato do template a clonar. Um módulo atende um sistema: o template precisa ser do mesmo os_type."
  type        = string

  validation {
    condition     = length(trimspace(var.template_name)) > 0
    error_message = "template_name não pode ser vazio."
  }
}

variable "datastore_default" {
  description = "Datastore usado quando a VM ou o disco extra não informa outro."
  type        = string

  validation {
    condition     = length(trimspace(var.datastore_default)) > 0
    error_message = "datastore_default não pode ser vazio."
  }
}

variable "default_dns_suffix" {
  description = "Domínio da customização Linux (FQDN) e sufixo DNS padrão do Linux quando dns_suffix_list é null. Exemplo: empresa.local."
  type        = string
  default     = "localdomain"

  validation {
    condition     = can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$", var.default_dns_suffix))
    error_message = "default_dns_suffix deve ser um nome DNS (letras, números, hífen e pontos)."
  }
}

variable "dns_suffix_list" {
  description = "Sufixos de busca DNS aplicados a todas as VMs. Null usa [default_dns_suffix] no Linux e omite o sufixo no Windows (compatível com estado antigo). Defina a lista para enviar dns_suffix_list também no Windows."
  type        = list(string)
  default     = null

  validation {
    condition = var.dns_suffix_list == null || (
      length(var.dns_suffix_list) > 0 && alltrue([
        for sufixo in var.dns_suffix_list : can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$", sufixo))
      ])
    )
    error_message = "dns_suffix_list, quando informado, precisa ter ao menos um sufixo DNS válido."
  }
}

variable "linux_time_zone" {
  description = "Fuso horário Linux (banco tz, por exemplo America/Sao_Paulo). Null mantém o padrão do provider (UTC) e não altera VM já clonada."
  type        = string
  default     = null

  validation {
    condition     = var.linux_time_zone == null || can(regex("^[A-Za-z0-9+\\-]+(?:/[A-Za-z0-9_+\\-]+)*$", var.linux_time_zone))
    error_message = "linux_time_zone deve ser um nome de fuso, como UTC ou America/Sao_Paulo."
  }
}

variable "windows_time_zone" {
  description = "Código numérico de fuso do Sysprep quando a VM não define windows_time_zone. Padrão 65 (SA Western Standard Time: Salvador/Manaus, GMT-3). 235 = Brasília, 85 = GMT, 255 = UTC."
  type        = number
  default     = 65

  validation {
    condition     = var.windows_time_zone >= 0 && var.windows_time_zone <= 65535 && var.windows_time_zone == floor(var.windows_time_zone)
    error_message = "windows_time_zone deve ser um inteiro entre 0 e 65535."
  }
}

variable "windows_admin_passwords" {
  description = "Senhas do administrador local Windows, indexadas pela mesma chave de vms. Obrigatório para cada VM quando os_type = windows. Variável sensitive: prefira TF_VAR_windows_admin_passwords e não grave em tfvars versionado."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    # try() porque o operador || não curto-circuita: a expressão da direita
    # também roda quando os_type = linux e a chave não existe no mapa.
    condition = var.os_type != "windows" || alltrue([
      for chave in keys(var.vms) : try(length(var.windows_admin_passwords[chave]), 0) > 0
    ])
    error_message = "Para cada chave de vms com os_type = windows, defina uma senha não vazia em windows_admin_passwords."
  }
}

variable "windows_product_keys" {
  description = "Product keys Windows, indexadas pela chave de vms. Omita a chave da VM para usar a licença do template. Variável sensitive."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for valor in values(var.windows_product_keys) : can(regex("^[A-Za-z0-9]{5}(?:-[A-Za-z0-9]{5}){4}$", valor))
    ])
    error_message = "Cada item de windows_product_keys deve usar o formato XXXXX-XXXXX-XXXXX-XXXXX-XXXXX. Omita a VM para herdar a licença do template."
  }
}

variable "domain_name" {
  description = "Domínio Active Directory para ingresso das VMs Windows. Null mantém o workgroup de cada VM. Uma implantação entra em um único domínio."
  type        = string
  default     = null

  validation {
    condition     = var.domain_name == null || can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$", var.domain_name))
    error_message = "domain_name deve ser um FQDN (ex.: empresa.local)."
  }

  validation {
    condition = var.domain_name == null || (
      var.os_type == "windows" &&
      try(length(trimspace(var.domain_admin_user)), 0) > 0 &&
      try(length(var.domain_admin_password), 0) > 0
    )
    error_message = "domain_name exige os_type = windows, domain_admin_user e domain_admin_password."
  }
}

variable "domain_admin_user" {
  description = "Conta com permissão de ingresso no Active Directory (usuario@dominio ou DOMINIO\\usuario). Obrigatória quando domain_name está definido."
  type        = string
  default     = null
}

variable "domain_admin_password" {
  description = "Senha da conta de ingresso no domínio. Sensitive. Prefira TF_VAR_domain_admin_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "domain_ou" {
  description = "OU de destino do computador no AD (ex.: OU=Servidores,DC=empresa,DC=local). Exige vSphere 8.0 Update 2 ou superior e não aceita espaços no caminho."
  type        = string
  default     = null

  validation {
    condition = var.domain_ou == null || (
      var.domain_name != null &&
      try(length(trimspace(var.domain_ou)), 0) > 0 &&
      !can(regex(" ", var.domain_ou))
    )
    error_message = "domain_ou exige domain_name e não pode conter espaços."
  }
}

variable "vms" {
  description = "Mapa de VMs clonadas do mesmo template. A chave entra no endereço do estado (não use dados sensíveis nela). Campos de Windows fora de os_type = windows são ignorados, e o inverso também."
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

  validation {
    condition = alltrue([
      for vm in values(var.vms) : can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", vm.vm_name))
    ])
    error_message = "vm_name deve ter de 1 a 63 caracteres, só letras, números e hífen, e precisa começar e terminar com caractere alfanumérico. Esse valor vira o nome no vCenter e o hostname."
  }

  validation {
    condition = var.os_type != "windows" || alltrue([
      for vm in values(var.vms) : length(vm.vm_name) <= 15
    ])
    error_message = "Com os_type = windows, vm_name é o computer name e o limite NetBIOS é 15 caracteres."
  }

  validation {
    condition = var.os_type != "windows" || alltrue([
      for vm in values(var.vms) : !contains(
        ["CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"],
        upper(vm.vm_name)
      )
    ])
    error_message = "vm_name não pode ser um nome reservado do Windows (CON, PRN, AUX, NUL, COM1-COM9, LPT1-LPT9)."
  }

  validation {
    condition     = length(distinct([for vm in values(var.vms) : upper(vm.vm_name)])) == length(var.vms)
    error_message = "vm_name precisa ser único neste mapa, sem diferenciar maiúsculas (o vCenter recebe o nome em maiúsculas)."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) : (
        vm.cpus >= 1 && vm.cpus == floor(vm.cpus) &&
        vm.memory_mb >= 1 && vm.memory_mb == floor(vm.memory_mb) &&
        vm.disk_size_gb >= 1 && vm.disk_size_gb == floor(vm.disk_size_gb)
      )
    ])
    error_message = "cpus, memory_mb e disk_size_gb devem ser inteiros positivos (cpus e memory_mb >= 1, disco >= 1 GB)."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) : (
        vm.netmask >= 1 && vm.netmask <= 32 && vm.netmask == floor(vm.netmask)
      )
    ])
    error_message = "netmask deve ser um prefixo IPv4 inteiro de 1 a 32 (ex.: 24)."
  }

  validation {
    condition = alltrue(flatten([
      for vm in values(var.vms) : concat(
        [
          can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$", vm.ip_address)),
          can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$", vm.gateway)),
        ],
        [
          for dns in vm.dns_servers : can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$", dns))
        ]
      )
    ]))
    error_message = "ip_address, gateway e cada item de dns_servers devem ser IPv4 em decimal pontuado, sem zeros à esquerda."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) : length(vm.dns_servers) > 0 && length(trimspace(vm.portgroup)) > 0
    ])
    error_message = "Cada VM precisa de portgroup preenchido e de ao menos um DNS."
  }

  validation {
    condition = length(distinct(flatten([
      for vm in values(var.vms) : concat(
        [vm.ip_address],
        [for nic in vm.extra_nics : nic.ip_address if nic.ip_address != null]
      )
      ]))) == length(flatten([
      for vm in values(var.vms) : concat(
        [vm.ip_address],
        [for nic in vm.extra_nics : nic.ip_address if nic.ip_address != null]
      )
    ]))
    error_message = "Cada IPv4 estático (NIC principal e extras) precisa ser único neste deploy."
  }

  validation {
    condition = alltrue(flatten([
      for vm in values(var.vms) : [
        for nic in vm.extra_nics : (
          length(trimspace(nic.portgroup)) > 0 &&
          (
            nic.ip_address == null ||
            can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$", nic.ip_address))
          ) &&
          (
            nic.ip_address == null
            ? true
            : nic.netmask != null && nic.netmask >= 1 && nic.netmask <= 32 && nic.netmask == floor(nic.netmask)
          )
        )
      ]
    ]))
    error_message = "NIC extra: portgroup obrigatório. Sem ip_address a NIC fica em DHCP. Com IP, informe netmask de 1 a 32 e um IPv4 válido."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) : length(vm.extra_disks) <= 14 && alltrue([
        for indice, disco in vm.extra_disks : (
          disco.size_gb >= 1 && disco.size_gb == floor(disco.size_gb) &&
          (disco.unit_number == null || (disco.unit_number >= 1 && disco.unit_number <= 15 && disco.unit_number != 7 && disco.unit_number == floor(disco.unit_number))) &&
          (disco.label == null || (!startswith(disco.label, "orphaned_disk_") && length(trimspace(disco.label)) > 0)) &&
          !(coalesce(disco.thin_provisioned, true) && coalesce(disco.eagerly_scrub, false)) &&
          (disco.datastore == null || length(trimspace(disco.datastore)) > 0)
        )
      ])
    ])
    error_message = "Disco extra: tamanho inteiro >= 1 GB, no máximo 14 discos, unit_number de 1 a 15 exceto 7, label sem o prefixo orphaned_disk_, e thin_provisioned não pode ser true junto com eagerly_scrub."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) : length(distinct(concat(
        [0],
        [for indice, disco in vm.extra_disks : (disco.unit_number != null ? disco.unit_number : (indice + 1 >= 7 ? indice + 2 : indice + 1))]
        ))) == length(vm.extra_disks) + 1 && length(distinct(concat(
        ["disk0"],
        [for indice, disco in vm.extra_disks : coalesce(disco.label, format("disk%d", indice + 1))]
      ))) == length(vm.extra_disks) + 1
    ])
    error_message = "unit_number e label dos discos precisam ser únicos na VM. O boot usa unit 0 e label disk0; a unidade 7 é do controlador SCSI."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) : (
        (vm.domain == null || can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$", vm.domain))) &&
        (vm.linux_time_zone == null || can(regex("^[A-Za-z0-9+\\-]+(?:/[A-Za-z0-9_+\\-]+)*$", vm.linux_time_zone))) &&
        (vm.windows_time_zone == null || (vm.windows_time_zone >= 0 && vm.windows_time_zone <= 65535 && vm.windows_time_zone == floor(vm.windows_time_zone))) &&
        length(vm.workgroup) >= 1 && length(vm.workgroup) <= 15 &&
        (vm.dns_suffix_list == null || (length(vm.dns_suffix_list) > 0 && alltrue([
          for sufixo in vm.dns_suffix_list : can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$", sufixo))
        ])))
      )
    ])
    error_message = "Revise domain, linux_time_zone, windows_time_zone (inteiro 0-65535), workgroup (1 a 15 caracteres) e dns_suffix_list da VM."
  }
}

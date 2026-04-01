# Terraform - VMs Windows no VMware vCenter 8

Clone de template Windows com configuracao automatica de rede, hostname, Sysprep e administrador local via **VMware Guest Customization** (`windows_options`).

Suporta multiplas VMs por execucao.

---

## Versoes Compativeis

| Sistema | Suporte |
|---|---|
| Windows Server 2016 | Sim |
| Windows Server 2019 | Sim |
| Windows Server 2022 | Sim |
| Windows 10 / 11 | Sim |

---

## Pre-requisitos do Template

- **VMware Tools** instalado e em execucao
- **Sysprep** - o vCenter executa automaticamente durante o clone quando o bloco `customize {}` esta presente; o template nao precisa ter Sysprep pre-executado, mas deve estar em um estado que o aceite

> Sem o VMware Tools instalado e em execucao, o processo de customizacao falha e a VM nao recebe hostname nem IP configurados automaticamente.

---

## O que o Sysprep configura automaticamente

Ao criar a VM, o Terraform executa o Sysprep via vCenter com as seguintes configuracoes:

| Item | Campo no tfvars | Descricao |
|---|---|---|
| Computer Name | `vm_name` | Nome do computador (max. 15 caracteres) |
| Senha Admin | `admin_password` | Senha do Administrador local |
| Proprietario | `full_name` | Registration Info - nome do proprietario |
| Organizacao | `organization_name` | Registration Info - nome da empresa |
| Licenca | `product_key` | Chave Windows (opcional - usa a do template se vazio) |
| Fuso Horario | `time_zone` | Codigo numerico do timezone Windows |
| Rede | `ip_address`, `netmask`, `gateway` | Configuracao IPv4 estatica |

---

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# edite o terraform.tfvars com seus dados

terraform init
terraform plan
terraform apply
```

---

## Variaveis de Infraestrutura

Configuradas no `terraform.tfvars`:

| Variavel | Obrigatorio | Descricao |
|---|---|---|
| `vsphere_server` | Sim | IP ou FQDN do vCenter |
| `vsphere_user` | Sim | Usuario do vCenter |
| `vsphere_password` | Sim | Senha do vCenter |
| `template_name` | Sim | Nome exato do template Windows no vCenter |
| `datacenter` | Sim | Nome do Datacenter |
| `cluster` | Sim | Nome do Cluster |
| `datastore_default` | Sim | Datastore padrao para as VMs |

---

## Campos por VM

Cada VM e um bloco dentro do mapa `vms` no `terraform.tfvars`:

| Campo | Obrigatorio | Descricao |
|---|---|---|
| `vm_name` | Sim | Nome da VM e computer name - **max. 15 caracteres** (limite NetBIOS) |
| `cpus` | Sim | Numero de vCPUs |
| `memory_mb` | Sim | Memoria em MB |
| `disk_size_gb` | Sim | Tamanho do disco em GB |
| `portgroup` | Sim | Nome exato do Port Group / DVPortGroup |
| `ip_address` | Sim | IP fixo |
| `netmask` | Sim | Prefixo CIDR numerico (ex: `24` para /24) |
| `gateway` | Sim | Gateway padrao |
| `dns_servers` | Sim | Lista de servidores DNS |
| `resource_pool` | Sim | `"CLUSTER/Resources"` ou `"CLUSTER/Resources/POOL"` |
| `admin_password` | Sim | Senha do Administrador local |
| `full_name` | Nao | Nome do proprietario - Registration Info (default: `Administrador`) |
| `organization_name` | Nao | Nome da organizacao - Registration Info (default: `Empresa`) |
| `product_key` | Nao | Chave de licenca Windows (default: vazio = usa a do template) |
| `workgroup` | Nao | Workgroup Windows (default: `WORKGROUP`) |
| `time_zone` | Nao | Codigo numerico do fuso horario (default: `65` = Salvador GMT-3) |
| `datastore` | Nao | Sobrescreve o `datastore_default` para esta VM |
| `folder` | Nao | Pasta no inventario vCenter (ex: `"VMs/Windows"`) |
| `annotation` | Nao | Descricao da VM (IP e concatenado automaticamente) |

### Codigos de Fuso Horario (`time_zone`)

| Codigo | Fuso | Observacao |
|---|---|---|
| `65` | SA Western Standard Time (GMT-3) | Salvador, Manaus - **sem horario de verao** (padrao) |
| `235` | E. South America Standard Time (GMT-3) | Brasilia - com ajuste de horario de verao |
| `85` | GMT Standard Time | Londres |
| `255` | UTC | Universal |

Lista completa: [Microsoft Time Zone Index Values](https://learn.microsoft.com/en-us/previous-versions/windows/embedded/ms912391(v=winembedded.11))

---

## Exemplo de terraform.tfvars

```hcl
vsphere_server     = "vcenter.empresa.local"
vsphere_user       = "administrator@vsphere.local"
vsphere_password   = "SENHA_AQUI"

datacenter         = "Datacenter"
cluster            = "Cluster"
template_name      = "TEMPLATE-WIN2022"
datastore_default  = "vsanDatastore"

vms = {
  "vm1" = {
    vm_name           = "WIN-APP-01"
    annotation        = "Windows Server 2022"
    cpus              = 4
    memory_mb         = 8192
    disk_size_gb      = 100
    portgroup         = "DVPG-PRODUCAO-100"
    ip_address        = "10.10.10.101"
    netmask           = 24
    gateway           = "10.10.10.1"
    dns_servers       = ["10.10.10.10", "10.10.10.11"]
    resource_pool     = "Cluster/Resources"
    admin_password    = "SenhaAdmin@123"
    full_name         = "Administrador"
    organization_name = "Minha Empresa"
    product_key       = ""
    workgroup         = "WORKGROUP"
    time_zone         = 65
  }
}
```

---

## Comportamento Automatico

| Recurso | Comportamento |
|---|---|
| Nome no vCenter | Sempre **MAIUSCULO** (`upper()`) |
| Computer Name | Sempre **MAIUSCULO** (`upper()`) |
| Annotation | IP concatenado automaticamente |
| Firmware | Herdado do template (EFI ou BIOS) |
| Sysprep | Executado automaticamente pelo vCenter durante o clone |

---

## Ingresso em Dominio AD

Para ingressar a VM em um dominio Active Directory ao inves de usar workgroup, substitua o campo `workgroup` pelos seguintes campos no bloco `windows_options` do `main.tf`:

```hcl
join_domain           = "dominio.local"
domain_admin_user     = "admin@dominio.local"
domain_admin_password = "SENHA_DOMINIO"
```

Documentacao do provider: [windows_options](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine#windows_options)

---

## Observacoes

- **Computer name:** o `vm_name` e usado como nome do computador Windows - limite de **15 caracteres** (restricao NetBIOS).
- **Licenca:** se `product_key` estiver vazio, a VM usa a licenca que ja esta no template. Util para templates com KMS ou licenca por volume.
- **Sem customizacao:** se preferir clonar sem configurar rede/hostname, remova o bloco `customize {}` dentro de `clone {}` no `main.tf`.
- **Multiplas VMs:** adicione mais blocos (`"vm2"`, `"vm3"`, ...) no mapa `vms`.
- **Credenciais:** o `terraform.tfvars` esta no `.gitignore`. Nunca o suba para o repositorio.
- **Novos deploys:** use workspaces ou diretorios separados para nao destruir VMs existentes (veja o README principal).

---

## Autor

**Matheus Corteletti**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/cortelettimatheus/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/wisecort)

# Terraform - VMs Linux no VMware vCenter 8

Clone de template Linux com configuracao automatica de rede e hostname via **VMware Guest Customization** (`linux_options`).

Suporta multiplas VMs por execucao.

---

## Distribuicoes Compativeis

| Distribuicao | Pacotes Obrigatorios |
|---|---|
| Oracle Linux / RHEL / CentOS / Rocky / Alma | `open-vm-tools` + `perl` |
| Ubuntu / Debian | `open-vm-tools` + `perl` |

> **IMPORTANTE:** O pacote `perl` e **obrigatorio** para que o VMware Guest Customization aplique hostname e IP automaticamente. Sem ele, a customizacao falha silenciosamente mesmo com `open-vm-tools` instalado.

### Instalacao no Template

```bash
# RHEL / Oracle Linux / CentOS / Rocky / AlmaLinux
dnf install -y open-vm-tools perl

# Ubuntu / Debian
apt install -y open-vm-tools perl
```

---

## Desabilitar IPv6 no Template

Para que todas as VMs clonadas ja nasçam com IPv6 desabilitado, execute no template **antes de converte-lo em template**:

```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

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
| `template_name` | Sim | Nome exato do template Linux no vCenter |
| `datacenter` | Nao | Nome do Datacenter (default: `Datacenter`) |
| `cluster` | Nao | Nome do Cluster (default: `Cluster`) |
| `datastore_default` | Nao | Datastore padrao (default: `vsanDatastore`) |
| `default_dns_suffix` | Nao | Sufixo DNS (default: `localdomain`) |

---

## Campos por VM

Cada VM e um bloco dentro do mapa `vms` no `terraform.tfvars`:

| Campo | Obrigatorio | Descricao |
|---|---|---|
| `vm_name` | Sim | Nome da VM (vCenter = MAIUSCULO, hostname = minusculo) |
| `cpus` | Sim | Numero de vCPUs |
| `memory_mb` | Sim | Memoria em MB |
| `disk_size_gb` | Sim | Tamanho do disco em GB |
| `portgroup` | Sim | Nome exato do Port Group / DVPortGroup |
| `ip_address` | Sim | IP fixo da VM |
| `netmask` | Sim | Prefixo CIDR numerico (ex: `24` para /24) |
| `gateway` | Sim | Gateway padrao |
| `dns_servers` | Sim | Lista de servidores DNS |
| `resource_pool` | Sim | `"CLUSTER/Resources"` ou `"CLUSTER/Resources/POOL"` |
| `datastore` | Nao | Sobrescreve o `datastore_default` para esta VM |
| `folder` | Nao | Pasta no inventario vCenter (ex: `"VMs/Linux"`) |
| `annotation` | Nao | Descricao da VM (IP e concatenado automaticamente) |

---

## Exemplo de terraform.tfvars

```hcl
vsphere_server     = "vcenter.empresa.local"
vsphere_user       = "administrator@vsphere.local"
vsphere_password   = "SENHA_AQUI"

template_name      = "TEMPLATE-UBUNTU2204"
datastore_default  = "vsanDatastore"
default_dns_suffix = "empresa.local"

vms = {
  "vm1" = {
    vm_name       = "LINUX-APP-01"
    annotation    = "Ubuntu 22.04"
    cpus          = 4
    memory_mb     = 8192
    disk_size_gb  = 100
    portgroup     = "DVPG-PRODUCAO-100"
    ip_address    = "10.10.10.101"
    netmask       = 24
    gateway       = "10.10.10.1"
    dns_servers   = ["10.10.10.10", "10.10.10.11"]
    resource_pool = "Cluster/Resources"
  }
}
```

---

## Comportamento Automatico

| Recurso | Comportamento |
|---|---|
| Nome no vCenter | Sempre **MAIUSCULO** (`upper()`) |
| Hostname do SO | Sempre **minusculo** (`lower()`) |
| Annotation | IP concatenado automaticamente |
| Firmware | Herdado do template (EFI ou BIOS) |

---

## Observacoes

- **Sem customizacao:** se o template nao tiver `open-vm-tools` e `perl`, remova o bloco `customize {}` dentro de `clone {}` no `main.tf`. A VM sera clonada sem configuracao automatica de rede.
- **Multiplas VMs:** adicione mais blocos (`"vm2"`, `"vm3"`, ...) no mapa `vms`.
- **Credenciais:** o `terraform.tfvars` esta no `.gitignore`. Nunca o suba para o repositorio.
- **Novos deploys:** use workspaces ou diretorios separados para nao destruir VMs existentes (veja o README principal).

---

## Autor

**Matheus Corteletti**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/cortelettimatheus/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/wisecort)

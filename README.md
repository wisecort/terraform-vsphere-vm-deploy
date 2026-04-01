# Terraform - Criacao de VMs no vCenter

Automacao para provisionar VMs no **VMware vCenter 8** via clone de template, com suporte a multiplas VMs por execucao e customizacao automatica de rede e hostname via **VMware Guest Customization**.

Suporta templates **Linux** (RHEL, Oracle Linux, Ubuntu, Debian, CentOS) e **Windows** (Server 2016/2019/2022, Windows 10/11).

---

## Estrutura do Projeto

```
.
├── linux/                    # Terraform para VMs Linux
│   ├── main.tf               # Recursos e data sources
│   ├── variables.tf          # Declaracao de variaveis
│   ├── outputs.tf            # Outputs (nome, IP, UUID)
│   ├── providers.tf          # Provider vsphere
│   ├── terraform.tfvars.example  # Exemplo de configuracao
│   ├── .gitignore
│   └── README.md
├── windows/                  # Terraform para VMs Windows
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── .gitignore
│   └── README.md
└── README.md                 # Este arquivo
```

---

## Pre-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- Acesso ao vCenter com permissoes de criacao de VMs
- Template preparado com VMware Tools (veja requisitos especificos no README de cada pasta)

---

## Quick Start

```bash
# 1. Entre na pasta do SO desejado
cd linux/          # ou cd windows/

# 2. Copie e edite o arquivo de configuracao
cp terraform.tfvars.example terraform.tfvars
# preencha com credenciais do vCenter, nome do template e dados das VMs

# 3. Execute
terraform init
terraform plan
terraform apply
```

---

## Comportamento Automatico

O Terraform aplica automaticamente as seguintes regras em todas as VMs criadas:

| Recurso | Comportamento |
|---|---|
| Nome no vCenter | Sempre em **MAIUSCULO** |
| Hostname Linux | Sempre em **minusculo** |
| Computer Name Windows | Sempre em **MAIUSCULO** |
| Annotation | IP concatenado automaticamente (ex: `Ubuntu \| IP: 10.10.10.101`) |
| Firmware | Herdado do template (EFI ou BIOS) |

---

## Criando novas VMs sem destruir as existentes

O Terraform gerencia o estado das VMs pelo arquivo `terraform.tfstate`. Se voce editar o `terraform.tfvars` removendo uma VM antiga para adicionar uma nova, ele vai **destruir a antiga e criar a nova**.

Use uma das estrategias abaixo para evitar isso.

### Opcao 1 - Workspaces (isolamento por deploy)

Cada workspace mantem um `terraform.tfstate` separado. VMs de workspaces diferentes nao se afetam.

```bash
cd linux/

# Primeiro deploy
terraform workspace new oracle-app-01
terraform apply

# Segundo deploy (nova VM independente)
terraform workspace new ubuntu-db-01
# edite o terraform.tfvars com os dados da nova VM
terraform apply

# Listar workspaces
terraform workspace list

# Trocar de workspace
terraform workspace select oracle-app-01

# Destruir apenas as VMs de um workspace
terraform workspace select oracle-app-01
terraform destroy
```

### Opcao 2 - Diretorio separado por deploy

Copie a pasta para um novo diretorio a cada deploy. Cada pasta tem seu proprio estado e e completamente independente.

```bash
cp -r linux/ deploys/oracle-app-01/
cd deploys/oracle-app-01/

cp terraform.tfvars.example terraform.tfvars
# edite o terraform.tfvars

terraform init
terraform plan
terraform apply
```

Estrutura sugerida:

```
.
├── linux/                       # Template original - nao altere
├── windows/                     # Template original - nao altere
├── deploys/
│   ├── oracle-app-01/           # Deploy independente
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── terraform.tfstate
│   ├── ubuntu-db-01/
│   └── windows-srv-01/
```

---

## Desabilitar IPv6 no Template Linux

As VMs clonadas herdam a configuracao de IPv6 do template. Para desabilitar o IPv6 em todas as VMs, execute os comandos abaixo **no template antes de converte-lo em template**:

```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

Assim toda VM clonada ja nasce com IPv6 desabilitado, sem necessidade de pos-configuracao.

---

## .gitignore Recomendado

```gitignore
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
```

---

## Autor

**Matheus Corteletti**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/cortelettimatheus/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/wisecort)

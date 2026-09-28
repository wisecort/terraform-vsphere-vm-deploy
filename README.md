# Terraform — VMs no VMware vCenter 8

Módulo para clonar VMs no **VMware vCenter 8** a partir de template, com customização de guest (rede e hostname) para **Linux** e **Windows**.

Um único módulo, `modules/vsphere-vm`, atende os dois sistemas pelo argumento `os_type`. Os diretórios `examples/linux` e `examples/windows` são roots finos: provider, backend e a chamada do módulo. Não há mais cópia do recurso `vsphere_virtual_machine` em cada sistema.

Para consumir uma versão fixa:

```hcl
module "vsphere_vm" {
  source = "git::https://github.com/wisecort/terraform-vsphere-vm-deploy.git//modules/vsphere-vm?ref=v1.0.0"
}
```

A tag `v1.0.0` deve ser criada em `main` depois que esta versão for mergeada. O histórico está no [CHANGELOG](CHANGELOG.md). Licença: [MIT](LICENSE).

---

## Estrutura

```
.
├── modules/vsphere-vm/          # Módulo (Linux e Windows)
├── examples/linux/              # Root de exemplo
├── examples/windows/
├── .github/workflows/terraform.yml
├── .pre-commit-config.yaml
├── .tflint.hcl
├── .terraform-docs.yml
├── CHANGELOG.md
└── LICENSE
```

---

## Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10
- vCenter 8 com template que já tenha VMware Tools
- Permissão para clonar e customizar na pasta, no cluster, no datastore e na rede usados

Linux: `open-vm-tools` e `perl` no template. Sem o `perl`, a customização de hostname e IP falha em silêncio.

```bash
# RHEL, Oracle Linux, CentOS, Rocky, Alma
dnf install -y open-vm-tools perl

# Ubuntu, Debian
apt install -y open-vm-tools perl
```

Windows: VMware Tools em execução. O vCenter roda o Sysprep no clone quando o bloco `customize` existe. O template não precisa ter sido sysprepado antes, mas precisa aceitar a customização. Compatível com Windows Server 2016, 2019 e 2022, e com Windows 10 e 11.

---

## Permissões mínimas no vCenter

Conjunto habitual para clonar template, customizar o guest, ligar a VM e destruí-la. Aplique na pasta de destino, no cluster, no datastore e no port group — não no vCenter inteiro. Estes nomes seguem a interface em português; o identificador da API vai entre parênteses. Não foi possível validar a lista contra um vCenter real.

| Área | Privilégio |
|---|---|
| Máquina virtual / Inventário | Criar a partir de existente (`VirtualMachine.Inventory.CreateFromExisting`), Criar novo (`VirtualMachine.Inventory.Create`), Remover (`VirtualMachine.Inventory.Delete`) |
| Máquina virtual / Interação | Ligar (`VirtualMachine.Interact.PowerOn`), Desligar (`VirtualMachine.Interact.PowerOff`) |
| Máquina virtual / Configuração | Adicionar novo disco (`VirtualMachine.Config.AddNewDisk`), Adicionar ou remover dispositivo (`VirtualMachine.Config.AddRemoveDevice`), Avançado (`VirtualMachine.Config.AdvancedConfig`), Alterar contagem de CPU (`VirtualMachine.Config.CPUCount`), Alterar memória (`VirtualMachine.Config.Memory`), Modificar configurações do dispositivo (`VirtualMachine.Config.EditDevice`), Alterar configurações (`VirtualMachine.Config.Settings`), Alterar recurso (`VirtualMachine.Config.Resource`), Renomear (`VirtualMachine.Config.Rename`), Definir anotação (`VirtualMachine.Config.Annotation`) |
| Máquina virtual / Provisionamento | Clonar modelo (`VirtualMachine.Provisioning.CloneTemplate`), Personalizar convidado (`VirtualMachine.Provisioning.Customize`), Implantar modelo (`VirtualMachine.Provisioning.DeployTemplate`), Ler especificações de personalização (`VirtualMachine.Provisioning.ReadCustSpecs`) |
| Datastore | Alocar espaço (`Datastore.AllocateSpace`), Procurar datastore (`Datastore.Browse`), Operações de arquivo de baixo nível (`Datastore.FileManagement`) |
| Rede | Atribuir rede (`Network.Assign`) |
| Recurso | Atribuir máquina virtual ao pool de recursos (`Resource.AssignVMToPool`) |

A pasta informada em `folder` precisa já existir. O módulo não cria pasta de inventário.

---

## Início rápido

```bash
export VSPHERE_SERVER="vcenter.empresa.local"
export VSPHERE_USER="administrator@vsphere.local"
export VSPHERE_PASSWORD="SENHA_AQUI"

cd examples/linux          # ou examples/windows
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
# edite os placeholders. Não coloque senha no tfvars.

terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

No Windows, a senha do administrador local vai à parte:

```bash
export TF_VAR_windows_admin_passwords='{"vm1":"SENHA_ADMIN_LOCAL"}'
```

Product key, se houver, segue o mesmo caminho (`TF_VAR_windows_product_keys`). Formato `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`. Sem a chave, a VM fica com a licença do template.

Para só validar a configuração, sem backend e sem vCenter:

```bash
terraform init -backend=false
terraform validate
```

---

## Credenciais

O provider lê sozinho, e os exemplos declaram `vsphere_server`, `vsphere_user` e `vsphere_password` com padrão `null`. Com `null`, valem as variáveis de ambiente:

| Variável de ambiente | Uso |
|---|---|
| `VSPHERE_SERVER` | Endereço do vCenter |
| `VSPHERE_USER` | Usuário |
| `VSPHERE_PASSWORD` | Senha |

Deixe as três variáveis Terraform em `null`. Não copie a senha para o `terraform.tfvars`. O estado remoto ainda guarda a senha do guest Windows quando ela entra na customização: restrinja quem lê o bucket ou o banco.

O módulo não configura o provider. Quem escrever o próprio root repete o bloco dos exemplos.

---

## Certificado TLS

`allow_unverified_ssl` nos exemplos vale `false`. vCenter com certificado público não precisa mudar nada. Laboratório com certificado autoassinado:

```hcl
allow_unverified_ssl = true
```

O argumento é explícito no provider, então `VSPHERE_ALLOW_UNVERIFIED_SSL` não substitui essa variável.

---

## Estado remoto e um deploy por estado

O estado local e o workspace não isolam bem quem trabalha em mais de uma máquina. Cada deploy é um root pequeno (pode partir do exemplo) com **um estado remoto e uma trava**.

O `versions.tf` dos exemplos deixa o backend parcial:

```hcl
backend "s3" {}
```

`examples/linux/backend.hcl.example` e `examples/windows/backend.hcl.example` mostram MinIO (e o que mudar para AWS S3). A trava é `use_lockfile = true` (Terraform >= 1.10). Não use `dynamodb_table`: no Terraform 1.16 esse argumento está depreciado, e o MinIO não implementa DynamoDB.

```bash
cp backend.hcl.example backend.hcl
# ajuste bucket, key e endpoint. Credenciais:
export AWS_ACCESS_KEY_ID="CHAVE"
export AWS_SECRET_ACCESS_KEY="SEGREDO"
terraform init -backend-config=backend.hcl
```

O `key` distingue o deploy. Exemplos de chave, ainda genéricos:

- `AMBIENTE/linux/terraform.tfstate`
- `AMBIENTE/windows/terraform.tfstate`

Dois deploys não compartilham o mesmo `key`. Apagar uma VM do mapa `vms` **destrói** essa VM no próximo apply, porque ela continua no mesmo estado. VM nova entra como mais uma chave no mapa, ou como outro root se o ciclo de vida for outro.

PostgreSQL, com trava nativa por advisory lock, está em `backend-pg.hcl.example`. Troque o bloco para `backend "pg" {}` e exporte `PG_CONN_STR`. Cada deploy usa um `schema_name` diferente.

`terraform.tfvars`, `backend.hcl` e `backend-pg.hcl` estão no `.gitignore`.

---

## Comportamento automático

| Recurso | Comportamento |
|---|---|
| Nome no vCenter | Sempre em **maiúsculas** |
| Hostname Linux | Sempre em **minúsculas** |
| Computer name Windows | Sempre em **maiúsculas**, no máximo 15 caracteres |
| Anotação | IP concatenado (`descricao \| IP: 192.168.1.101`) |
| Firmware | Herdado do template (EFI ou BIOS) |
| Pool de recurso | O valor de `resource_pool`, ou o pool raiz do cluster quando vem vazio |
| Disco de boot | Tamanho pedido, desde que não seja menor que o do template |
| Template recriado | `template_uuid` novo **não** recria VM já existente |

Atualizar o template (Packer, nova conversão, mesmo nome, outro UUID) mudaria `clone.template_uuid`. O provider trata mudança dentro de `clone` como substituição da VM. O `lifecycle.ignore_changes` inclui `clone[0].template_uuid` para impedir essa recriação. `disk[0].eagerly_scrub` e `firmware` continuam ignorados, como no layout anterior: o template reporta oscilação que não é mudança real de disco ou firmware.

IP, hostname, senha e fuso continuam visíveis no plano. Se mudarem depois da criação, o provider propõe **recriar** a VM. Isso é proposital: a customização só roda no clone.

---

## Discos, NICs, fuso e Active Directory

**Discos extras** em `extra_disks`. Até 14, além do boot. A unidade SCSI 7 pertence ao controlador; o módulo pula esse número quando `unit_number` fica omisso. `thin_provisioned = true` não combina com `eagerly_scrub = true`. O disco pode apontar para outro `datastore`.

**NICs extras** em `extra_nics`. Sem `ip_address`, a interface fica em DHCP. Com IP, `netmask` é obrigatório (1–32). O gateway padrão continua único: o provider não configura gateway por interface.

**Fuso Linux:** `linux_time_zone` no módulo ou na VM (`America/Sao_Paulo`, `America/Bahia`, `America/Manaus`, `UTC`). Lista de nomes aceitos pelo vSphere: [VMware KB 2145518](https://knowledge.broadcom.com/external/article/321332). Omitir preserva o padrão do provider (UTC) e não mexe em VM já clonada.

**Fuso Windows:** código numérico do Sysprep.

| Código | Fuso |
|---|---|
| `65` | SA Western Standard Time (Salvador, Manaus, GMT-3). Padrão |
| `235` | E. South America Standard Time (Brasília, GMT-3) |
| `85` | GMT Standard Time |
| `255` | UTC |

Lista da Microsoft: [Time Zone Index Values](https://learn.microsoft.com/en-us/previous-versions/windows/embedded/ms912391(v=winembedded.11)).

**Active Directory:** defina `domain_name`, `domain_admin_user` e `domain_admin_password` (sensitive). O `workgroup` da VM deixa de ser enviado. `domain_ou` é opcional e exige vSphere 8.0 Update 2, sem espaços no caminho LDAP. Todas as VMs daquele root entram no mesmo domínio. Ambientes mistos (um no domínio, outro em workgroup) são dois deploys.

**DNS no Windows:** o Linux sempre manda `[default_dns_suffix]` quando `dns_suffix_list` é null. No Windows a lista só é enviada se você definir `dns_suffix_list` (no módulo ou na VM). O exemplo Windows já define. Além da lista global, a primeira entrada vai para `dns_domain` da NIC, que é o campo que o Sysprep realmente usa. Em VM Windows **já existente**, passar a lista muda o bloco `clone` e o plano pode propor substituir a VM. Na migração, omita `dns_suffix_list` se quiser conservar as VMs.

---

## IPv6 no template Linux

A VM clonada herda o IPv6 do template. Para nascer desligado, rode no template **antes** de convertê-lo:

```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

---

## Referência do módulo

Tabelas geradas por [terraform-docs](https://terraform-docs.io/) a partir de `modules/vsphere-vm`. Não edite entre os marcadores. Rode `bash scripts/terraform-docs.sh` para atualizar este arquivo e o README do módulo.

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

O mesmo bloco está em [modules/vsphere-vm/README.md](modules/vsphere-vm/README.md).

---

## Migração de `linux/` e `windows/`

Os roots antigos foram removidos. O estado que eles geraram continua válido se o endereço da VM for reescrito. Não rode `terraform destroy` no diretório antigo.

1. Copie o root novo a partir de `examples/linux` ou `examples/windows` (ou escreva um root que chame o módulo com os mesmos nomes: módulo `vsphere_vm`, recurso `vsphere_virtual_machine.vm`).
2. Copie o `terraform.tfstate` antigo para esse diretório, ou suba para o backend remoto com `terraform init -migrate-state`.
3. Os exemplos trazem:

   ```hcl
   moved {
     from = vsphere_virtual_machine.vm
     to   = module.vsphere_vm.vsphere_virtual_machine.vm
   }
   ```

   O bloco reassocia todas as instâncias do `for_each`. Sem estado antigo, o Terraform ignora. Data sources mudam de endereço e são lidos de novo; isso não desliga VM.
4. Se o plano reclamar do provider, rode uma vez:

   ```bash
   terraform state replace-provider -auto-approve hashicorp/vsphere vmware/vsphere
   ```

5. Ajuste o `terraform.tfvars`:
   - Tire `admin_password` e `product_key` de dentro de `vms`.
   - Exporte `TF_VAR_windows_admin_passwords` e, se usar, `TF_VAR_windows_product_keys`, com a **mesma chave** do mapa (`vm1`, etc.) e o **mesmo valor** de antes. Senha diferente altera a customização e o provider propõe recriar a VM.
   - Renomeie `time_zone` para `windows_time_zone`.
   - Nomes agora precisam ser hostname: letras, números e hífen, começando e terminando com alfanumérico. No Windows, no máximo 15 caracteres.
   - `allow_unverified_ssl` era `true` fixo. O padrão agora é `false`. Certificado autoassinado exige `allow_unverified_ssl = true`.
   - `datacenter`, `cluster` e `datastore_default` não têm mais placeholder (`Datacenter`, `Cluster`, `Datastore`). Informe os nomes reais. No root Windows eles já eram obrigatórios.
6. `terraform plan` antes de qualquer apply. A VM deve aparecer como **moved**, não como destroy/create. Se o plano mostrar substituição, pare e leia a causa (em geral customização nova, senha diferente ou `dns_suffix_list` no Windows).

Quem não usar os exemplos cola o mesmo bloco `moved` no root próprio. O destino tem de ser `module.vsphere_vm.vsphere_virtual_machine.vm`, ou o nome que você der ao módulo.

---

## Desenvolvimento

Com Terraform 1.16, TFLint 0.64 e Trivy 0.74:

```bash
terraform fmt -check -recursive

for diretorio in modules/vsphere-vm examples/linux examples/windows; do
  terraform -chdir="$diretorio" init -backend=false -input=false
  terraform -chdir="$diretorio" validate
done

tflint --init
for diretorio in modules/vsphere-vm examples/linux examples/windows; do
  tflint --chdir="$diretorio" --config="$PWD/.tflint.hcl"
done

for diretorio in modules/vsphere-vm examples/linux examples/windows; do
  trivy config --severity HIGH,CRITICAL --exit-code 1 --skip-dirs .terraform "$diretorio"
done
```

O workflow [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) roda esses checks em pull request e em push na `main`. O [`.pre-commit-config.yaml`](.pre-commit-config.yaml) repete fmt, validate, tflint e trivy, e atualiza as tabelas do terraform-docs.

Não há teste contra vCenter neste repositório: `validate` não abre sessão e não avalia `precondition`.

---

## Autor

**Matheus Corteletti**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/cortelettimatheus/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/wisecort)

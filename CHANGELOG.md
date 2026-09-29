# Changelog

Todas as mudanças relevantes deste projeto estão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e o projeto adota [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2026-09-28

Primeira versão consumível como módulo. A tag `v1.0.0` deve ser criada em `main` depois do merge.

### Adicionado

- Módulo `modules/vsphere-vm` para clonar VMs Linux e Windows a partir de um template no vCenter 8, selecionado por `os_type`.
- Exemplos `examples/linux` e `examples/windows` que só chamam o módulo.
- Discos extras, NICs extras (IP estático ou DHCP), fuso horário Linux e ingresso opcional no Active Directory no Windows, com OU (`domain_ou`, vSphere 8.0 Update 2).
- `dns_suffix_list` também no Windows, inclusive `dns_domain` na interface, quando a lista é informada.
- Validações de prefixo de rede, IPv4, CPU, memória, nome da VM e limite NetBIOS de 15 caracteres.
- `precondition` que impede disco menor que o do template.
- `allow_unverified_ssl` configurável, padrão `false`.
- Backend parcial S3/MinIO com `use_lockfile` e exemplo alternativo PostgreSQL (`backend-pg.hcl.example`).
- Blocos `moved` nos exemplos para o recurso `vsphere_virtual_machine.vm` do layout antigo.
- Workflow de GitHub Actions, `.tflint.hcl`, `.pre-commit-config.yaml` e tabelas do terraform-docs.
- `.terraform.lock.hcl` versionado.
- Licença MIT.

### Alterado

- Provider de `hashicorp/vsphere` `~> 2.6` para `vmware/vsphere` `~> 2.17`. O namespace antigo parou na 2.12.0; a manutenção passou para a VMware em maio de 2025.
- Terraform mínimo de `>= 1.5` para `>= 1.10`, pela validação entre variáveis e pela trava `use_lockfile` do backend S3.
- `admin_password` e `product_key` saíram do mapa `vms` e viraram `windows_admin_passwords` e `windows_product_keys`, ambas `sensitive`.
- O fuso Windows por VM passou de `time_zone` para `windows_time_zone`.
- O data source de cluster agora escolhe o resource pool raiz quando `resource_pool` vem vazio.
- `ignore_changes` passa a incluir `clone[0].template_uuid`, além de `disk[0].eagerly_scrub` e `firmware`.
- Credenciais do vCenter ficam em `VSPHERE_SERVER`, `VSPHERE_USER` e `VSPHERE_PASSWORD`.

### Removido

- Roots duplicados `linux/` e `windows/`.
- Orientação de isolar deploy com workspace ou cópia integral da pasta. O estado remoto, com um `key` ou schema por deploy, substitui esse fluxo.
- `.terraform.lock.hcl` do `.gitignore`.

### Segurança

- Senha de administrador, product key e senha de domínio não aparecem mais como atributo comum do mapa de VMs.
- TLS do vCenter deixa de aceitar certificado inválido por padrão.

[1.0.0]: https://github.com/wisecort/terraform-vsphere-vm-deploy/releases/tag/v1.0.0

# Exemplo Linux

Root mínimo que chama [`modules/vsphere-vm`](../../modules/vsphere-vm) com `os_type = "linux"`.

O passo a passo, o estado remoto e a migração do antigo diretório `linux/` estão no [README do repositório](../../README.md).

```bash
export VSPHERE_SERVER="vcenter.empresa.local"
export VSPHERE_USER="administrator@vsphere.local"
export VSPHERE_PASSWORD="SENHA_AQUI"

cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl

terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

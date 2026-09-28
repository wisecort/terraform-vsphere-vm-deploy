# Exemplo Windows

Root mínimo que chama [`modules/vsphere-vm`](../../modules/vsphere-vm) com `os_type = "windows"`.

Senha de administrador, product key e senha de domínio são variáveis `sensitive`. Passe por `TF_VAR_*`, não pelo `terraform.tfvars`. O restante do fluxo está no [README do repositório](../../README.md).

```bash
export VSPHERE_SERVER="vcenter.empresa.local"
export VSPHERE_USER="administrator@vsphere.local"
export VSPHERE_PASSWORD="SENHA_AQUI"
export TF_VAR_windows_admin_passwords='{"vm1":"SENHA_ADMIN_LOCAL"}'

cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl

terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

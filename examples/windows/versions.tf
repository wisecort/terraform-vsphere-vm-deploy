terraform {
  required_version = ">= 1.10.0"

  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.17"
    }
  }

  # Configuração parcial. O arquivo real fica de fora do Git.
  #   terraform init -backend-config=backend.hcl
  # CI e validação local:
  #   terraform init -backend=false
  backend "s3" {}
}

provider "vsphere" {
  # Null usa VSPHERE_SERVER, VSPHERE_USER e VSPHERE_PASSWORD.
  # Não preencha senha em terraform.tfvars.
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = var.allow_unverified_ssl
}

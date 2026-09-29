terraform {
  required_version = ">= 1.10.0"

  required_providers {
    vsphere = {
      source = "vmware/vsphere"
      # 2.17 acompanha o provider mantido pela VMware (Broadcom).
      # A faixa ~> 2.17 aceita correções da mesma minor e não pula para 2.18
      # sem uma revisão, já que este repositório não tem vCenter para testar.
      version = "~> 2.17"
    }
  }
}

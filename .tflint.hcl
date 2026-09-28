config {
  # Os exemplos chamam o módulo por caminho local. Inspecionar a chamada
  # pega argumento desconhecido sem analisar o módulo duas vezes no CI:
  # o job roda tflint em cada diretório.
  call_module_type = "local"
  force            = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

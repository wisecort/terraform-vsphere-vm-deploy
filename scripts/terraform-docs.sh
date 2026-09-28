#!/usr/bin/env bash
# Regenera as tabelas do módulo e copia o mesmo bloco para o README da raiz.
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
cd "$raiz"

terraform-docs -c .terraform-docs.yml modules/vsphere-vm

python3 - <<'PY'
from pathlib import Path

inicio = "<!-- BEGIN_TF_DOCS -->"
fim = "<!-- END_TF_DOCS -->"
modulo = Path("modules/vsphere-vm/README.md").read_text()
raiz_md = Path("README.md").read_text()
bloco = modulo[modulo.index(inicio) : modulo.index(fim) + len(fim)]
antes = raiz_md.index(inicio)
depois = raiz_md.index(fim) + len(fim)
Path("README.md").write_text(raiz_md[:antes] + bloco + raiz_md[depois:])
PY

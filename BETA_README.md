# Engage — Beta

## Iniciar em qualquer computador

Depois de clonar ou atualizar o repositório, execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\INICIAR_ENGAGE.ps1
```

O script verifica os pré-requisitos, instala `openpyxl` quando necessário e inicia a aplicação em:

- Dashboard: http://127.0.0.1:8765/
- API SQLite: http://127.0.0.1:8767/api/periods

Para apenas validar os pré-requisitos:

```powershell
powershell -ExecutionPolicy Bypass -File .\INICIAR_ENGAGE.ps1 -CheckOnly
```

## Importação trimestral

Cada Account Owner envia um par de arquivos `.xlsx`: Engage/Compliance e Especializações.

Ambos precisam conter uma aba `IMPORT_META` com:

| Campo | Exemplo |
|---|---|
| ACCOUNT_OWNER | Debora Scardino Mancebo |
| YEAR | 2026 |
| QUARTER | Q3 |
| DATASET_TYPE | ENGAGE_COMPLIANCE ou SPECIALIZATIONS |

Uma nova carga do mesmo Account Owner/Ano/Quarter cria outra versão e preserva a anterior. A exclusão de uma versão ativa reativa automaticamente a versão anterior, quando existir.

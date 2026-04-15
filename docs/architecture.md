# Arquitetura do produto

## Decisao principal

Para este caso, a melhor arquitetura nao e Python puro na interface. A recomendacao e:

- Cliente cross-platform em Flutter para Android, iPhone e desktop.
- Banco local no cliente para autosave e operacao offline.
- Backend em Python/FastAPI como hub de sincronizacao, backups, conciliacao e integracoes externas.
- Banco relacional em nuvem para sincronizacao, auditoria e historico.

## Por que esta arquitetura

- Flutter entrega melhor UX visual e responsividade real em Android, iPhone e desktop com uma unica base.
- Python segue onde ele gera mais valor: integracoes, regras de negocio, webhooks, relatorios, exportacoes e automacoes.
- A separacao evita acoplar a interface a regras financeiras sensiveis.

## Camadas

### 1. Cliente local-first

- Cadastro rapido de clientes, vendas, gastos, assinaturas e retiradas.
- Autosave imediato em banco local.
- Fila de alteracoes pendentes.
- Dashboard e alertas com leitura rapida.
- Operacao offline por padrao.

### 2. Sync/Cloud

- Recebe lotes de mudancas do cliente.
- Distribui mudancas recentes para outros dispositivos.
- Mantem revisao por registro.
- Abre conflito quando um registro financeiro foi alterado em dois dispositivos com revisoes diferentes.

### 3. Integradores

- Lastlink: ingestao de webhooks para criar/atualizar vendas automaticamente.
- Cora: preparado para extrato, saldo e webhooks via API oficial quando houver credenciais.
- Mercado Pago: preparado para futuro conector de pagamentos e notificacoes.

## Regras de negocio centrais

- `gross_amount`: valor bruto da venda.
- `platform_fee_amount + payment_fee_amount`: descontos da plataforma/meio de pagamento.
- `net_amount`: valor liquido antes da comissao do Daniel.
- `commissionable_amount`: parte da receita que entra na regra de comissao.
- `daniel_amount`: `commissionable_amount * daniel_percent`.
- `owner_net_amount`: valor final que sobra para voce.

Formula padrao do MVP:

```text
net_amount = gross_amount - platform_fee_amount - payment_fee_amount
commissionable_amount = commissionable_amount informado ou net_amount
daniel_amount = commissionable_amount * daniel_percent (se houver participacao)
owner_net_amount = net_amount - daniel_amount
```

## Escopo do MVP

- CRUD de clientes
- CRUD de vendas/recebimentos
- CRUD de gastos
- CRUD de assinaturas
- Registro de retiradas da empresa para voce
- Dashboard com saldos, entradas, saidas, a receber, recebido, em aberto e alertas
- Backup exportavel
- Base de sync
- Webhook Lastlink

## Itens deliberadamente deixados para fases seguintes

- Conciliacao bancaria automatica completa
- Parcelas detalhadas por recebivel
- OCR/importacao de comprovantes
- Regras avancadas por produto/plataforma
- Engine de recomendacoes com historico maior


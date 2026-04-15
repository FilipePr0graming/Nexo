# Integracoes oficiais consideradas

## Lastlink

Baseado na documentacao oficial publica de webhook da Lastlink:

- Os eventos sao enviados por `HTTP POST` em `application/json`.
- Todo evento possui `Id`, `IsTest`, `Event`, `CreatedAt` e `Data`.
- Ha eventos como `Purchase_Order_Confirmed`, `Recurrent_Payment`, `Payment_Refund`, `Payment_Chargeback`, `Subscription_Canceled` e outros.
- O payload pode incluir objetos como `Buyer`, `Products`, `Offer`, `Commissions`, `Purchase`, `Subscriptions`, `Utm` e `DeviceInfo`.

Decisao de arquitetura:

- O MVP usa Lastlink para criar rascunhos confiaveis de vendas/clientes via webhook.
- O MVP nao assume liquidacao financeira final automaticamente, porque a documentacao publica encontrada descreve eventos de compra/pagamento e nao uma API publica de extrato completo de repasse para conciliacao bancaria final.
- Quando o repasse real nao puder ser inferido com seguranca, a venda entra como pendente de conciliacao.

## Cora

Baseado na documentacao oficial de desenvolvedores da Cora:

- Existem modos de integracao `Parceria Cora` e `Integracao Direta`.
- A autenticacao oficial pode exigir `client_id`, `client_secret` ou `client_id + certificado + private key`, dependendo da modalidade.
- A Cora documenta APIs de saldo, extrato e webhooks.
- Ha ambiente `stage` e ambiente de producao.
- A Cora recomenda uso de `Idempotency-Key` em chamadas que criam operacoes.

Decisao de arquitetura:

- O sistema nasce com um `provider adapter` para Cora.
- A automacao real fica bloqueada ate existirem credenciais oficiais, certificado e private key validos.
- Quando liberado, o conector da Cora deve ser a fonte principal de conciliacao de saldo e extrato para entradas/saidas em conta.

## Mercado Pago

- O projeto ja nasce com um slot de integracao para Mercado Pago.
- No MVP, a entrada continua manual ou via webhook futuro.
- A automacao fica para a fase 2, com credenciais e modelagem de notificacoes/pagamentos.

